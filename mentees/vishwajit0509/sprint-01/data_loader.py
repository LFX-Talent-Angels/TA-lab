import pandas as pd
import os


def extract_and_clean_data(file_path):
    print(f"Reading data from {file_path}...")

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Missing file: {file_path}")
    
    df = pd.read_excel(file_path, sheet_name='Table 1.2', skiprows=1)
    df.columns = df.columns.str.replace('\n', ' ').str.replace('�', '–').str.strip()
    col_mapping = {
        '2024 National Employment Matrix title': 'title',
        '2024 National Employment Matrix code': 'soc_code',
        'Occupation type': 'occupation_type',
        'Employment, 2024': 'base_employment',
        'Employment, 2034': 'projected_employment',
        'Employment change, percent, 2024–34': 'percent_change',
        'Median annual wage, dollars, 2024[1]': 'median_wage',
        'Typical education needed for entry': 'entry_education'
    }

    df = df.rename(columns=col_mapping)

    if 'occupation_type' in df.columns:
        df = df[df['occupation_type']=='Line item'].copy()
    
    
    df = df.replace(['—', '-'], None)
    
    
    columns_to_keep = ['soc_code', 'title', 'base_employment', 'projected_employment', 'percent_change', 'median_wage', 'entry_education']

    existing_cols = [col for col in columns_to_keep if col in df.columns]

    df = df[existing_cols]

    df = df.dropna(subset=['soc_code','title'])

    print(f"Successfully processed {len(df)} detailed occupations.")

    return df



