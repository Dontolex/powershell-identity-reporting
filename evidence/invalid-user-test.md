# Invalid-user test record

Source: terminal output supplied by the lab operator, followed by local inspection of the reports directory. This is a transcribed test record, not a raw terminal log or screenshot.

- Date: 25 September 2026, 12:23:23 UTC.
- Input UserId: `00000000-0000-0000-0000-000000000000`.
- Failure location: `Get-MgUser`, script line 28.
- HTTP status: `404 (NotFound)`.
- Graph error code: `Request_ResourceNotFound`.
- Message: the specified resource does not exist or a queried reference-property object is not present.
- Verification: the reports directory contained only the two previous successful reports, from 12:06:59 and 12:10:46 UTC. No new report was present for this attempt.

The failed lookup stopped execution before report creation. It was not recorded as a valid zero-group result. This test covers a nonexistent user, not all possible query failures.
