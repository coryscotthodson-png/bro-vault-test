flowchart TD
A[Attacker] --> B[attackOnce(2712)]
B --> C[mint()]
B --> D[reentryHook()]
D --> E[mint reentry]
C --> F[balance += tokens]
E --> F
F --> G[Inflated state]
G --> H[4x balance observed]
