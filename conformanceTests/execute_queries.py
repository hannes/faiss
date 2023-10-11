import duckdb
import gzip
import pickle
import numpy

# need an unsigned flag for now
con = duckdb.connect(config = {'allow_unsigned_extensions': 'true'})
con.sql("LOAD '../build/release/extension/faiss/faiss.duckdb_extension'")
print("loading index!")
con.sql("CALL FAISS_LOAD('flat', 'index')")
print("loading queries!")
embedings = con.from_query("FROM 'anserini-tools/topics-and-qrels/topics.dl19-passage.openai-ada2.jsonl.gz'").project("qid, vector AS embedding")
print("querying")
results = embedings.project("qid, UNNEST(FAISS_SEARCH('flat', 1000, emb))")
print(results)
