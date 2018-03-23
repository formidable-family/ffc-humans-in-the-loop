import pandas as pd
import numpy as np
import copy

with open('../../data/variables/ffvars_scored.csv') as file:
    df = pd.read_csv(file, sep=',', na_values="NA")
    variables = pd.unique(df['ffvar'])
    print "Number of unique variables considered: {0}".format(len(variables))

    # Print the mapping between ideas and 'ffvar' for manuscript
    missing = df['ffvar'].isnull()
    mapping = {}
    for i, row in df.iterrows():
        key = row['idea']; variable = row['ffvar']
        if missing[i]: continue
        if mapping.has_key(key):
            mapping[key].add(variable)
        else:
            mapping[key] = set([variable])

    print "Number of predictor ideas considered: {0}".format(len(mapping))

    # for idea, variables in mapping.items():
    #     print "Idea: {0}\tVariables: {1}".format(idea, variables)

    # Save this mapping to a latex table
    mapping = pd.DataFrame(mapping.items(), columns=['predictor', 'variable'])
    with open('table.tex', 'w') as table:
	    table.write(mapping.to_latex(column_format='ll', index=False))
