# Referência Técnica: Padrões de Logs e Linguagens

## 1. Python
- **Padrão de Erro:** `Traceback (most recent call last):`
- **Tipos Frequentes:** `NameError`, `TypeError`, `KeyError`, `AttributeError`, `IndentationError`, `MemoryError`, `ConnectionRefusedError`.
- **Pontos de Atenção:** Importações circulares, conexões HTTP não fechadas (`urllib3` / `requests` connection pool full).

## 2. Java / Kotlin / JVM
- **Padrão de Erro:** `Exception in thread "..." java.lang...` ou linhas iniciadas por `	at `
- **Tipos Frequentes:** `NullPointerException`, `OutOfMemoryError: Java heap space`, `StackOverflowError`, `ClassNotFoundException`, `SQLException`, `TimeoutException`.
- **Pontos de Atenção:** `Caused by:` encadeados, estouro de PermGen/Metaspace, thread deadlock (`Waiting on condition`).

## 3. JavaScript / TypeScript / Node.js
- **Padrão de Erro:** `UnhandledPromiseRejectionWarning:`, `Error: ... at ...`
- **Tipos Frequentes:** `TypeError: Cannot read property ... of undefined`, `ECONNREFUSED`, `ETIMEDOUT`, `ERR_HTTP_HEADERS_SENT`.
- **Pontos de Atenção:** Leaks de event loop, Promises sem `.catch()`, estouro de memória (`FATAL ERROR: CALL_AND_RETRY_LAST Allocation failed - JavaScript heap out of memory`).

## 4. Go (Golang)
- **Padrão de Erro:** `panic: runtime error: ...`
- **Tipos Frequentes:** `nil pointer dereference`, `concurrent map read and map write`, `goroutine leak`, `context deadline exceeded`.
- **Pontos de Atenção:** Goroutines presas aguardando canais sem buffer, estouro de conexões de banco de dados (`database/sql`).

## 5. Rust
- **Padrão de Erro:** `thread 'main' panicked at ...`
- **Tipos Frequentes:** `unwrap()` em `None`/`Err`, `out of bounds`, `borrow checker failure` em tempo de execução via `RefCell`.

## 6. C / C++
- **Padrão de Erro:** `Segmentation fault (core dumped)`, `double free or corruption`, `corrupted size vs. prev_size`.
- **Pontos de Atenção:** Acesso inválido a ponteiros, estouro de buffer (buffer overflow), vazamentos de memória (Valgrind warnings em logs).

## 7. C# / .NET
- **Padrão de Erro:** `Unhandled exception. System....Exception:`
- **Tipos Frequentes:** `NullReferenceException`, `AggregateException`, `TaskCanceledException`, `SqlException`.

## 8. Containers & Infraestrutura (Docker, K8s, Nginx)
- **Docker/K8s:** `OOMKilled`, `CrashLoopBackOff`, `ImagePullBackOff`, `Liveness probe failed`.
- **Nginx/Apache:** `502 Bad Gateway`, `504 Gateway Timeout`, `499 Client Closed Request`, `worker_connections are not enough`.
