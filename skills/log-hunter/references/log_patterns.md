# Referência Técnica: Padrões de Logs por Linguagem e Plataforma

Assinaturas atuais (runtimes suportados em 2026). Quando uma assinatura antiga aparecer, ela também diz algo: o runtime está desatualizado.

## 1. Python (3.10+)
- **Erro:** `Traceback (most recent call last):` — a causa está na **última** linha; em cadeias, procure `The above exception was the direct cause of` / `During handling of the above exception`.
- **Frequentes:** `KeyError`, `TypeError`, `AttributeError: 'NoneType' object has no attribute`, `ModuleNotFoundError`, `MemoryError`, `ConnectionRefusedError`, `TimeoutError`, `sqlalchemy.exc.OperationalError`, `psycopg.OperationalError`.
- **Servidores:** Gunicorn `[CRITICAL] WORKER TIMEOUT (pid:N)` (requisição mais lenta que `--timeout`); `Worker (pid:N) was sent SIGKILL! Perhaps out of memory?`; Uvicorn `Exception in ASGI application`.
- **Assíncrono:** `Task exception was never retrieved` e `coroutine '...' was never awaited` (erro silencioso: a exceção não sobe).
- **Atenção:** `urllib3 ... Connection pool is full, discarding connection`.

## 2. Java / Kotlin / JVM (17 e 21 LTS)
- **Erro:** `Exception in thread "..." java...`, linhas `\tat ...`; a causa raiz está no **último** `Caused by:`.
- **Memória:** `java.lang.OutOfMemoryError: Java heap space`, `...: Metaspace` (PermGen **não existe** desde o Java 8; se aparecer, a JVM é antiga), `...: Direct buffer memory`, `GC overhead limit exceeded`. Em container, OOM do kernel (exit 137) sem `OutOfMemoryError` no log indica heap + memória nativa maior que o limit do pod: revisar `-XX:MaxRAMPercentage`.
- **Log de GC (JDK 9+, unified logging):** `[gc] GC(123) Pause Young (Normal) (G1 Evacuation Pause) 512M->128M(1024M) 15.2ms`; `Pause Full` frequente = pressão de memória. O formato `[GC (Allocation Failure)` é do JDK 8.
- **Spring Boot / pools:** `HikariPool-1 - Connection is not available, request timed out after 30000ms` (pool esgotado), `Connection reset`, `Application run failed`, `APPLICATION FAILED TO START`.
- **Threads:** `Found one Java-level deadlock`; com virtual threads (Java 21), `Thread ... pinned` indica bloqueio em `synchronized`.

## 3. JavaScript / TypeScript / Node.js (20+)
- **Rejeição não tratada:** desde o Node 15 o processo **cai**: `[UnhandledPromiseRejection: This error originated either by throwing inside of an async function without a catch block...]` ou o próprio erro seguido de `Node.js v20...`. O antigo `UnhandledPromiseRejectionWarning` só aparece em Node ≤ 14 (runtime sem suporte).
- **Frequentes:** `TypeError: Cannot read properties of undefined (reading 'x')` (forma atual; `Cannot read property 'x' of undefined` é de Node ≤ 14), `ECONNREFUSED`, `ECONNRESET`, `ETIMEDOUT`, `EADDRINUSE`, `ERR_HTTP_HEADERS_SENT`.
- **Memória:** `FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory` (ajustar `--max-old-space-size` ao limit do container).

## 4. Go
- **Erro:** `panic: runtime error: ...` seguido de `goroutine N [running]:`; `fatal error: concurrent map read and map write`; `fatal error: all goroutines are asleep - deadlock!`.
- **Frequentes:** `invalid memory address or nil pointer dereference`, `context deadline exceeded`, `context canceled`, `dial tcp ...: connect: connection refused`, `i/o timeout`.

## 5. Rust
- **Erro:** `thread 'main' panicked at src/...` (formato atual: arquivo:linha na mesma linha) com a mensagem na linha seguinte; `called \`Option::unwrap()\` on a \`None\` value`; `already borrowed: BorrowMutError`.

## 6. C / C++
- **Erro:** `Segmentation fault (core dumped)`, `double free or corruption`, `malloc(): corrupted top size`, `stack smashing detected`, `terminate called after throwing an instance of`.

## 7. C# / .NET (8+)
- **Erro:** `Unhandled exception. System....Exception:`; `fail: Microsoft.AspNetCore...` (nível de log ASP.NET Core).
- **Frequentes:** `NullReferenceException`, `TaskCanceledException` / `OperationCanceledException` (geralmente timeout de HttpClient), `SqlException ... Timeout expired`, `Microsoft.Data.SqlClient.SqlException`, `System.OutOfMemoryException`.

## 8. PHP
- `PHP Fatal error:  Allowed memory size of N bytes exhausted`, `Uncaught Error:`, `PHP Warning:`; PHP-FPM `server reached pm.max_children setting` (falta de workers).

## 9. Containers e Kubernetes
| Sinal | Significado |
|---|---|
| Exit code **137** | SIGKILL: quase sempre **OOMKilled** (confira `Last State: Terminated, Reason: OOMKilled` no `describe`) ou kill após `terminationGracePeriodSeconds` |
| Exit code **143** | SIGTERM: desligamento pedido (deploy, scale-down, eviction, liveness falhando) |
| Exit code **1** / **2** | Erro da aplicação na inicialização: leia o log `--previous` |
| Exit code **126/127** | Comando não executável / não encontrado (imagem ou `command` errado) |
| Exit code **139** | Segmentation fault |
| `Back-off restarting failed container` | CrashLoopBackOff: o primeiro erro está no log `--previous`, não no atual |
| `Liveness probe failed` seguido de restart | Probe derrubando o container: verificar se a probe depende de banco ou é lenta demais |
| `Readiness probe failed` | Pod fora do balanceamento (sem restart) |
| `ImagePullBackOff` / `ErrImagePull` | Imagem, tag ou credencial do registry |
| `FailedScheduling ... Insufficient memory/cpu` | Falta de capacidade ou requests altos |
| `Evicted ... The node was low on resource: memory/ephemeral-storage` | Pressão no node |

## 10. Proxies e Web
- **Nginx / Ingress NGINX:** `upstream timed out (110: Connection timed out)`, `connect() failed (111: Connection refused) while connecting to upstream`, `no live upstreams`, `worker_connections are not enough`; status **502** (upstream caiu/recusou), **504** (upstream lento), **499** (cliente desistiu).
- **Envoy / Gateway API / Istio:** `upstream connect error or disconnect/reset before headers`, flags de resposta `UF` (falha de conexão upstream), `UT` (timeout), `NR` (sem rota), `UH` (nenhum host saudável).
- **Apache:** `AH01102: error reading status line from remote server`, `AH00124: Request exceeded the limit of 10 internal redirects`.
