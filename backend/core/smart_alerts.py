"""
core/smart_alerts.py — Generador de Alertas Financieras Inteligentes

Responsabilidades:
1. Analizar el estado presupuestal y de metas del usuario en base a reglas de negocio.
2. Generar y registrar alertas inteligentes en la base de datos (CRITICA, ADVERTENCIA, INFORMATIVA, MOTIVACIONAL).
3. Evitar alertas duplicadas o spam para el usuario en el mismo periodo.
4. Entregar una lista de alertas ordenadas por prioridad para el consumo en el frontend de Flutter.
"""

from datetime import date
from sqlalchemy.orm import Session
from sqlalchemy import and_, extract, func, not_

from db.models import Alert, Expense, Goal, Budget
from core.enums import TipoAlerta, EstadoMeta, CategoriaGasto
from core.budgets import obtener_presupuesto_activo
from core.exceptions import PresupuestoNoEncontradoError

def _obtener_promedio_historico_categoria(
    db: Session, 
    user_id: int, 
    categoria: CategoriaGasto, 
    mes_actual: int, 
    anio_actual: int
) -> float:
    """
    Calcula el promedio de gasto mensual histórico para una categoría específica,
    excluyendo el mes actual.
    """
    # 1. Agrupar gastos anteriores por mes y año para sumar el monto mensual
    resultados_mensuales = db.query(
        extract('year', Expense.fecha).label('anio'),
        extract('month', Expense.fecha).label('mes'),
        func.sum(Expense.monto).label('total_mes')
    ).filter(
        and_(
            Expense.user_id == user_id,
            Expense.categoria == categoria,
            not_(
                and_(
                    extract('year', Expense.fecha) == anio_actual,
                    extract('month', Expense.fecha) == mes_actual
                )
            )
        )
    ).group_by(
        extract('year', Expense.fecha),
        extract('month', Expense.fecha)
    ).all()

    if not resultados_mensuales:
        return 0.0

    # 2. Calcular el promedio de esas sumas mensuales
    total_historico = sum(row.total_mes for row in resultados_mensuales)
    cantidad_meses = len(resultados_mensuales)

    return total_historico / cantidad_meses if cantidad_meses > 0 else 0.0

def generar_alertas_usuario(db: Session, user_id: int) -> None:
    """
    Ejecuta las reglas de negocio financieras para generar alertas en la base de datos.
    Evita registrar alertas duplicadas dentro del mismo mes corriente.
    """
    hoy = date.today()
    mes_actual = hoy.month
    anio_actual = hoy.year

    # --- REGLA 1: ADVERTENCIA (Gasto > 80% antes del día 20) ---
    try:
        budget = obtener_presupuesto_activo(db, user_id)
        if hoy.day < 20 and budget.monto_base > 0:
            porcentaje_gastado = (budget.total_gastado / budget.monto_base) * 100
            if porcentaje_gastado > 80.0:
                titulo_adv = "Alerta de Presupuesto: Límite del 80%"
                # Verificar si ya existe esta alerta este mes
                existe = db.query(Alert).filter(
                    and_(
                        Alert.user_id == user_id,
                        Alert.titulo == titulo_adv,
                        extract('month', Alert.created_at) == mes_actual,
                        extract('year', Alert.created_at) == anio_actual
                    )
                ).first()

                if not existe:
                    dias_restantes = 30 - hoy.day # Estimación simple
                    mensaje = (
                        f"¡Cuidado! Has consumido el {porcentaje_gastado:.1f}% de tu presupuesto base "
                        f"antes del día 20. Aún quedan aproximadamente {dias_restantes} días de mes. "
                        f"Te sugerimos moderar tus gastos no esenciales."
                    )
                    db.add(Alert(
                        user_id=user_id,
                        titulo=titulo_adv,
                        mensaje=mensaje,
                        tipo=TipoAlerta.ADVERTENCIA
                    ))
    except PresupuestoNoEncontradoError:
        pass # Si no hay presupuesto, no podemos evaluar gastos vs límites del mes

    # --- REGLA 2: CRÍTICA (Gasto en categoría supera 150% del promedio histórico) ---
    # Solo evaluamos si hay gastos este mes
    gastos_mes_actual = db.query(
        Expense.categoria,
        func.sum(Expense.monto).label('total_categoria')
    ).filter(
        and_(
            Expense.user_id == user_id,
            extract('month', Expense.fecha) == mes_actual,
            extract('year', Expense.fecha) == anio_actual
        )
    ).group_by(Expense.categoria).all()

    for row in gastos_mes_actual:
        cat = row.categoria
        total_este_mes = float(row.total_categoria) if row.total_categoria else 0.0
        
        promedio_historico = _obtener_promedio_historico_categoria(db, user_id, cat, mes_actual, anio_actual)
        
        # Evaluamos solo si hay datos históricos suficientes (>0) para comparar de forma justa
        if promedio_historico > 0 and total_este_mes > (1.5 * promedio_historico):
            titulo_critica = f"Gasto Inusual: {cat.value.capitalize()}"
            
            # Evitar alertas repetidas este mes
            existe = db.query(Alert).filter(
                and_(
                    Alert.user_id == user_id,
                    Alert.titulo == titulo_critica,
                    extract('month', Alert.created_at) == mes_actual,
                    extract('year', Alert.created_at) == anio_actual
                )
            ).first()

            if not existe:
                mensaje = (
                    f"¡Alerta crítica! Tus gastos en la categoría '{cat.value.capitalize()}' "
                    f"ascienden a S/. {total_este_mes:.2f}, lo cual supera en más del 150% "
                    f"tu promedio histórico de S/. {promedio_historico:.2f} para esta categoría. "
                    f"Revisa tus comprobantes para identificar posibles fugas."
                )
                db.add(Alert(
                    user_id=user_id,
                    titulo=titulo_critica,
                    mensaje=mensaje,
                    tipo=TipoAlerta.CRITICA
                ))

    # --- REGLA 3: INFORMATIVA (Meta al 90% o más de completarse) ---
    metas_casi_listas = db.query(Goal).filter(
        and_(
            Goal.user_id == user_id,
            Goal.estado == EstadoMeta.EN_PROGRESO,
            Goal.monto_objetivo > 0
        )
    ).all()

    for goal in metas_casi_listas:
        porcentaje_ahorro = (goal.saldo_acumulado / goal.monto_objetivo) * 100
        if 90.0 <= porcentaje_ahorro < 100.0:
            titulo_info = f"Meta casi lista: {goal.nombre}"
            
            # Evitar alertas spam para la misma meta si ya se notificó
            existe = db.query(Alert).filter(
                and_(
                    Alert.user_id == user_id,
                    Alert.titulo == titulo_info
                )
            ).first()

            if not existe:
                faltante = goal.monto_objetivo - goal.saldo_acumulado
                mensaje = (
                    f"¡Excelente noticia! Tu meta '{goal.nombre}' está al {porcentaje_ahorro:.1f}% de completarse. "
                    f"Solo te faltan S/. {faltante:.2f} para alcanzar tu objetivo de S/. {goal.monto_objetivo:.2f}. "
                    f"¡Estás a un solo paso!"
                )
                db.add(Alert(
                    user_id=user_id,
                    titulo=titulo_info,
                    mensaje=mensaje,
                    tipo=TipoAlerta.INFORMATIVA
                ))

    # --- REGLA 4: MOTIVACIONAL (% gastado < 50% en el día 15) ---
    if hoy.day == 15:
        try:
            budget = obtener_presupuesto_activo(db, user_id)
            if budget.monto_base > 0:
                porcentaje_gastado = (budget.total_gastado / budget.monto_base) * 100
                if porcentaje_gastado < 50.0:
                    titulo_mot = "¡Vas por excelente camino!"
                    
                    # Evitar duplicar
                    existe = db.query(Alert).filter(
                        and_(
                            Alert.user_id == user_id,
                            Alert.titulo == titulo_mot,
                            extract('month', Alert.created_at) == mes_actual,
                            extract('year', Alert.created_at) == anio_actual
                        )
                    ).first()

                    if not existe:
                        mensaje = (
                            f"¡Felicidades! Estamos a mitad de mes y solo has consumido el {porcentaje_gastado:.1f}% "
                            f"de tu presupuesto mensual base. Mantener esta disciplina financiera te permitirá "
                            f"ahorrar más o cumplir tus metas antes de tiempo."
                        )
                        db.add(Alert(
                            user_id=user_id,
                            titulo=titulo_mot,
                            mensaje=mensaje,
                            tipo=TipoAlerta.MOTIVACIONAL
                        ))
        except PresupuestoNoEncontradoError:
            pass

    db.commit()

def obtener_alertas_priorizadas(db: Session, user_id: int) -> list[Alert]:
    """
    Retorna la lista de todas las alertas activas del usuario, 
    ordenadas estrictamente por su nivel de importancia:
    CRITICA (1) -> ADVERTENCIA (2) -> INFORMATIVA (3) -> MOTIVACIONAL (4)
    Y secundariamente por fecha de creación (de más reciente a más antigua).
    """
    # Ejecutamos la generación para asegurar alertas frescas
    generar_alertas_usuario(db, user_id)

    # Obtenemos las alertas
    alertas = db.query(Alert).filter(
        and_(
            Alert.user_id == user_id,
            Alert.leida == False
        )
    ).all()

    # Mapeo de prioridad para ordenación en Python (más simple y flexible)
    prioridad_map = {
        TipoAlerta.CRITICA: 1,
        TipoAlerta.ADVERTENCIA: 2,
        TipoAlerta.INFORMATIVA: 3,
        TipoAlerta.MOTIVACIONAL: 4
    }

    # Ordenar por prioridad del mapa y luego de forma descendente por fecha de creación
    alertas_ordenadas = sorted(
        alertas, 
        key=lambda x: (prioridad_map.get(x.tipo, 99), x.created_at),
        reverse=False # Queremos prioridad 1 (CRITICA) al inicio
    )

    return alertas_ordenadas
