MERGE (o:Organism {taxid: $taxid})
ON CREATE SET
    o.sciname = $sciname
