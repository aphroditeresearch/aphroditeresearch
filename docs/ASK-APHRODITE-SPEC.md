# ASK APHRODITE — Backend Spec

*The blueprint for the fully-functional AI version. The retrieval assistant shipped in
`ask.html` is the safe front-end today; this is what turns it into a real AI that can
answer open questions — built the way that keeps it trustworthy and legally safe.*

---

## The non-negotiable: it is NOT an open chatbot

Ask Aphrodite must never behave like a general LLM that answers peptide questions from
its training data. That path guarantees three failures: it will hallucinate studies,
it will eventually give dosing/personal-use guidance when phrased cleverly, and it will
state things with confidence the evidence doesn't support. Any of those destroys the
one asset the whole site is built on — trust.

So the architecture is **retrieval-augmented generation (RAG) with a hard safety gate**,
not a chatbot. The model only ever summarizes retrieved, reviewed records. If nothing
relevant is retrieved, it says so — it does not improvise.

## Architecture

```
User question
     │
1. SAFETY CLASSIFIER  ── is this a dosing / personal-use / sourcing question?
     │        │
     │        └── YES → return the refuse-and-explain response. No model call. Log it.
     │
2. RETRIEVE  ── embed the question, search the vetted knowledge base
     │           (only reviewed compound records + citations)
     │
3. GROUNDED?  ── did we retrieve relevant, reviewed content?
     │      │
     │      └── NO → "not in my reviewed knowledge yet" + list what IS covered. No model call.
     │
4. GENERATE  ── model answers USING ONLY the retrieved records, with a strict system prompt:
     │           • never invent studies, numbers, or citations
     │           • keep human evidence separate from animal
     │           • never give dosing, protocols, administration, or sourcing
     │           • cite the source record for every claim
     │           • if the records don't answer it, say so
     │
5. POST-CHECK ── scan the generated answer for dosing/number leakage before returning
     │
6. RETURN  ── answer + source links + evidence tags. Log Q&A for review.
```

## The safety gate (steps 1 and 5)

Two layers, because one isn't enough:

**Pre-filter (step 1):** keyword + intent classifier catches "how much," "dose," "mg/mcg,"
"protocol," "cycle," "stack," "reconstitute," "inject," "where to buy," "source," "vendor,"
etc. These never reach the model — they get the refuse-and-explain response directly.

**Post-filter (step 5):** even a well-behaved model can slip. After generation, scan the
output for dose-like patterns (numbers + mg/mcg/iu, "per week," titration language). If
found, suppress the answer and return the refusal instead. Belt and suspenders.

The refusal is always **refuse + explain + redirect**: decline, explain *why* (most of
these compounds have almost no human safety data; a "recommended dose" is guessing with
someone's health; and a site that hands out protocols becomes the thing it's fighting),
then offer the studied-record — what doses appeared *in published trials*, reported as a
record, never as a recommendation.

## The knowledge base

Not the open web, not the model's training data. A curated store you control:
- One vetted record per compound-outcome pair (the same data behind the dossiers)
- Every record carries its citations and an evidence grade
- Chunked and embedded for semantic retrieval
- Updated only through human review (this is where Radar feeds in — new studies become
  new/updated records after a human approves them)

If it's not in the KB, Ask Aphrodite doesn't know it. That's a feature.

## Build stack (suggested)

- **Front end:** the existing `ask.html` chat UI — swap its local `KB` array for API calls
- **API:** a serverless function (Vercel/Cloudflare) holding the model key server-side
  (never in the browser)
- **Vector store:** Supabase pgvector, Pinecone, or similar for the embedded KB
- **Model:** any capable LLM API, called only in step 4, tightly system-prompted
- **Logging:** store every question + answer + which path it took (answer / refuse /
  unknown) for weekly human review — this is how you catch drift and improve the KB

## What stays the same as the shipped version

The user experience, the tone, the refuse-and-explain behavior, the "reviewed knowledge
only" honesty, and the source-linking are all already built in `ask.html`. The backend
just makes it able to handle questions that aren't pre-written — without giving up any of
the safety. The front end doesn't need to change much; the intelligence moves server-side.

## Honest scope

This is a real build — a safety classifier, a vector store, a server endpoint, a tuned
system prompt, and a review-logging loop. It's very doable, and none of it is exotic. But
it is the backend phase, and it should only be built once the site has an audience that's
actually asking questions worth answering. Until then, the retrieval version in `ask.html`
covers the launch compounds honestly and safely.
