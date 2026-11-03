# Referência Técnica: Auditoria de Segurança e RBAC

## Checklist de Segurança do Pod e Container

0. **Pod Security Admission (PSA):**
   - Namespaces de aplicação sem a label `pod-security.kubernetes.io/enforce` não têm nenhuma barreira contra pods privilegiados. Recomendar `baseline` no mínimo e `restricted` onde possível (começar com `warn`/`audit` para medir impacto).

1. **Privilégios e Contexto de Segurança:**
   - Detectar `privileged: true` em `securityContext`.
   - Identificar containers executando como root (`runAsUser: 0` ou `allowPrivilegeEscalation: true`).
   - Verifique `readOnlyRootFilesystem`: recomendar onde aplicável.
   - Checar suporte a `capabilities` (ex.: remoção de `ALL` e adição pontual apenas de necessárias).

2. **Segurança de RBAC e Service Accounts:**
   - Identificar Pods utilizando ServiceAccount `default` com permissões atreladas.
   - Verificar privilégios de ClusterRoleBindings e RoleBindings excessivos (ex.: `*` em verbos ou recursos, acesso a `secrets`).
   - Checar `automountServiceAccountToken: true` em ServiceAccounts que não necessitam de comunicação com a API do Kubernetes.

3. **Exposição de Rede:**
   - Detectar `hostNetwork: true`, `hostPID: true`, `hostIPC: true`.
   - Identificar Services do tipo `NodePort` ou `LoadBalancer` sem restrição de IP de origem (`loadBalancerSourceRanges`).
   - Verificar ausência de `NetworkPolicies` ativas liberando tráfego não restrito (ingress/egress) em namespaces com dados sensíveis.
