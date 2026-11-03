# Referência Técnica: Erros Silenciosos e Riscos Futuros

## 1. Vazamento de Recursos e Memória
- **Sintomas nos Logs:** Crescimento gradual no tempo de resposta, Garbage Collection cada vez mais frequente (JDK 9+: `[gc] GC(n) Pause Full ...`; JDK 8: `[GC (Allocation Failure) ...]`), aumento na latência de I/O, restarts com exit code 137 em intervalos regulares.
- **Risco:** Reinicialização repentina do processo por OOMKilled sem que o log grave um erro direto de aplicação.

## 2. Exhaustion de Pool de Conexões
- **Sintomas nos Logs:** Warnings como `Timeout waiting for connection from pool`, `Too many connections`, `Connection acquisition timeout`.
- **Risco:** Bloqueio total da aplicação (Deadlock) quando o tráfego aumenta ligeiramente.

## 3. Retries Infinitos e Degradação de Conectividade
- **Sintomas nos Logs:** Repetição excessiva de tentativas de reconexão (`Retrying connection in 1s... 2s... 4s...`).
- **Risco:** Efeito cascata em microsserviços e consumo excessivo de CPU/Sockets (EPI - Ephemeral Port Exhaustion).

## 4. Logs de Depreciação e Configurações Incorretas
- **Sintomas nos Logs:** `DEPRECATION WARNING`, `SSL/TLS Certificate expiring in X days`, `Using default secret key`.
- **Risco:** Falha de produção em atualizações de versão ou brechas graves de segurança.
