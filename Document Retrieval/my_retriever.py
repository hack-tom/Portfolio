import math


class Retrieve:
    # Create new Retrieve object storing index and termWeighting scheme
    def __init__(self, index, termWeighting):
        # Assign index attribute (Inverted File Index).
        self.index = index
        # Assign term weighting attribute.
        self.termWeighting = termWeighting
        # |D| - Get the set of documents on the second level of the index via
        # set comprehension,
        # Take the length of this set to get the number of documents.
        self.numDocs = len({doc for word in self.index.values() for doc in word})

        # Initialise a list to store the length of each document (faster than dictionary for this task) (Σd^2).
        self.d_len = [0]*self.numDocs
        if self.termWeighting == "binary":
            # Loop through each word in dictionary.
            for (word, docs) in self.index.items():
                # Loop through each doc for that word.
                for (doc, weight) in docs.items():
                    # Increment document length for each word.
                    self.d_len[doc-1] += 1
        elif self.termWeighting == "tf":
            # Loop through each word in dictionary.
            for (word, docs) in self.index.items():
                # Loop through each doc containing that word.
                for (doc, weight) in docs.items():
                    # Square term frequency and add it to document vector length.
                    self.d_len[doc-1] += weight**2
        elif self.termWeighting == "tfidf":
            # df - Get dictionary of Document Frequencies - get number of documents
            # for each word in the index.
            self.df = {term: len(docs) for (term, docs) in self.index.items()}
            # idf - Get dictionary of IDF values - divide size of collection (numDocs) by document frequency for a given word.
            self.idf = {term: math.log(self.numDocs / frequency) for (term, frequency) in self.df.items()}
            # tfidf - Get dictionary of TFIDF values - two level dictionary. Cycle through all documents for a given word and multiply term frequency by IDF for that word.
            # Dictionary structure identical to that of index (Inverted File Index).
            self.tfidf = {word: {doc: frequency * self.idf[word] for (doc, frequency) in docs.items()} for (word, docs) in self.index.items()}
            # Loop through each word in TFIDF adjusted dictionary.
            for (word, docs) in self.tfidf.items():
                # Loop through each document containing that word.
                for (doc, weight) in docs.items():
                    # Square the tfidf value for the given word and add it to document vector length.
                    self.d_len[doc-1] += weight**2

        # Square each value to get document length.
        self.d_len = [doc**0.5 for doc in self.d_len]

    # Method performing retrieval for specified query.
    def forQuery(self, query):
        # Each element stores a sum of products for weights of terms in the query and the corresponding weight for a term in the corpus (Σqd).
        qd_sum = [0]*self.numDocs

        # This code runs when tfidf is the selected weighting method.
        if self.termWeighting == "tfidf":
            # Loop through words in the query.
            for word in query:
                # If the word is also in the index... (Get candidate documents)
                if word in self.tfidf:
                    # Get the tfidf weight for that word in the query (tfidf of words in query but not index evaluates to 0).
                    qt_tfidf = query[word] * self.idf[word]
                    # We want the list of documents the word appears in...
                    docs = self.index[word]
                    # We want to add the product between query weight and document weight to the document's element in qd_sum.
                    for (doc, weight) in docs.items():
                        qd_sum[doc-1] += weight * qt_tfidf

        # This code runs when term frequency is the selected weighting method.
        elif self.termWeighting == "tf":
            # Loop through words in the query.
            for word in query:
                # If the word is also in the index... (Get candidate documents)
                if word in self.index:
                    # We want the list of documents the word appears in...
                    docs = self.index[word]
                    # We want to add the product between query term frequency and document term frequency to the document's element in qd_sum.
                    for (doc, weight) in docs.items():
                        qd_sum[doc-1] += weight * query[word]

        # This code runs when binary is the selected weighting method.
        elif self.termWeighting == "binary":

            # Loop through words in the query.
            for word in query:
                # If the word is also in dictionary... (Get candidate documents)
                if word in self.index:
                    # We want the list of documents the word appears in...
                    docs = self.index[word]
                    # We want to increment the element of qd_sum which stores word matches for this document
                    for doc in docs:
                        qd_sum[doc-1] += 1

        # Get cosine similarity between each document and the query.
        cos_score = [qd/d for qd, d in zip(qd_sum, self.d_len)]

        # Get the 10 most similar documents to the query by sorting cosine similarity list and returning indexes of maximal elements.
        best_elements = sorted(range(len(cos_score)), key=lambda i: cos_score[i])[-10:]

        # Index 0 corresponds to Document 1, Index 1 to Document 2 etc, so
        # increment each of the top ten values by one and return.
        return [e + 1 for e in best_elements]