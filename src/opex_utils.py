"""
Утилиты для анализа OPEX буровых операций АО «Волковгеология».
Utility functions for Volkovgeology drilling OPEX analysis.
"""

import pandas as pd
import numpy as np


def load_operations(path='../data/raw/drilling_operations.csv'):
    """Загрузка и парсинг данных буровых операций."""
    df = pd.read_csv(path, parse_dates=['дата_начала', 'дата_окончания'])
    df['year_month'] = df['дата_начала'].dt.to_period('M')
    return df


def load_deposits(path='../data/raw/deposits.csv'):
    """Загрузка справочника месторождений."""
    return pd.read_csv(path)


def load_cost_categories(path='../data/raw/cost_categories.csv'):
    """Загрузка справочника статей затрат."""
    return pd.read_csv(path)


def remove_test_records(df):
    """
    Удаление тестовых записей (МСТ-000 / ТЕСТОВОЕ).
    
    Returns
    -------
    pd.DataFrame, int (cleaned data, count of removed rows)
    """
    mask = (df['код_месторождения'] == 'МСТ-000') | (df['наименование_месторождения'] == 'ТЕСТОВОЕ')
    n_removed = mask.sum()
    return df[~mask].copy(), n_removed


def calculate_cost_per_meter(operations):
    """
    Расчёт стоимости бурения на метр по каждой скважине.
    
    Returns
    -------
    pd.DataFrame with номер_скважины, наименование_месторождения, 
                      глубина_факт_м, total_cost, cost_per_meter
    """
    well_costs = operations.groupby(
        ['номер_скважины', 'наименование_месторождения', 'глубина_факт_м']
    ).agg(
        total_cost=('факт_тыс_тнг', 'sum'),
        total_plan=('план_тыс_тнг', 'sum')
    ).reset_index()
    
    well_costs['cost_per_meter'] = (well_costs['total_cost'] / well_costs['глубина_факт_м']).round(2)
    well_costs['plan_per_meter'] = (well_costs['total_plan'] / well_costs['глубина_факт_м']).round(2)
    well_costs['variance_pct'] = ((well_costs['total_cost'] - well_costs['total_plan']) / well_costs['total_plan'] * 100).round(1)
    
    return well_costs


def flag_anomalies(operations, threshold_pct=15):
    """
    Пометка аномальных отклонений план/факт.
    
    Parameters
    ----------
    operations : pd.DataFrame
    threshold_pct : float, порог отклонения в процентах
    
    Returns
    -------
    pd.DataFrame with added column 'is_anomaly'
    """
    df = operations.copy()
    df['отклонение_пцт'] = (df['факт_тыс_тнг'] - df['план_тыс_тнг']) / df['план_тыс_тнг'] * 100
    df['is_anomaly'] = df['отклонение_пцт'].abs() > threshold_pct
    return df