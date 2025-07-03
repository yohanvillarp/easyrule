# Reglas

Este documento describe las reglas y relaciones necesarias para automatizar la generación de comandos iptables sin errores. Está basado en las constantes definidas en el script.

---

## Estructura general de comandos
iptables [-t TABLA] COMANDO CADENA [OPCIONES] [-j ACCIÓN]


- **TABLA**: Puede ser `filter`, `nat`, `mangle`, `raw`, `security`
- **COMANDO**: Por ejemplo `-A`, `-L`, `-D`, etc.
- **CADENA**: (depende de la tabla)
- **OPCIONES**: Parámetros como `-s`, `-d`, `--dport`, etc.
- **ACCIÓN**: Objetivo final como `ACCEPT`, `DROP`, etc.

---

## Reglas por comando

### Comando `-L` (listar reglas)
- Solo permite las opciones `-n`, `--line-numbers`, `-v`
- Se puede omitir la cadena (muestra todas las disponibles en la tabla)
- Es válido en todas las tablas

### Solución
- 1.creación de constante OPCIONES_COMANDO_L=("-n" "--line-numbers" "-v")
- 3.Ya es valido en todas las tablas

### Comando `-I` (insertar)
- Puede aceptar un número de posición (entero positivo) tras la cadena
- Requiere que la cadena exista

### Solución
- 1. Ya existe la logica necesaria

### Comando `-D` (borrar)
- Puede aceptar:
  - Una regla exacta (como con `-A`)
  - Un número de línea (requiere `--line-numbers`)

### Comando `-F`, `-X` (limpiar/eliminar)
- La cadena no es obligatoria

### Solución
- 1. Ya existe la logica necesaria

---

## Reglas por tabla y cadenas permitidas

| Tabla     | Cadenas permitidas                          |
|-----------|---------------------------------------------|
| filter    | INPUT, OUTPUT, FORWARD                      |
| nat       | PREROUTING, POSTROUTING, OUTPUT             |
| mangle    | PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING |
| raw       | PREROUTING, OUTPUT                          |
| security  | INPUT, FORWARD, OUTPUT                      |


### Solución
- Las constantes ya existen
---

## Reglas de acciones (objetivo `-j`)

| Tabla     | Acciones permitidas               |
|-----------|-----------------------------------|
| filter    | ACCEPT, DROP, REJECT, LOG         |
| mangle    | ACCEPT, DROP, LOG                 |
| raw       | NOTRACK                           |
| nat       | No definidas (no usar)            |
| security  | No definidas (no usar)            |

### SOlución
- Constantes y logica ya implementada
---

## Reglas de módulos (`-m`) y sus estados

**Módulos disponibles**:
- `state --state`
- `conntrack --ctstate`

**Estados posibles**:
- NEW, ESTABLISHED, RELATED, INVALID

**Tablas permitidas**:
- filter
- mangle
- nat

**Restricciones**:
- No usar con `raw` ni `security`
- `state` y `conntrack` no pueden usarse simultáneamente
- Si se usa `--state` o `--ctstate`, debe incluirse su módulo correspondiente (`-m state` o `-m conntrack`)


### SOlución
- implementado
---

## Reglas de puertos (`--dport`, `--sport`)

- Solo pueden usarse si se especifica previamente `-p` con valor `tcp` o `udp`


---

## Reglas para interfaces de red

| Opción | Uso permitido en cadenas           |
|--------|------------------------------------|
| `-i`   | INPUT, PREROUTING                  |
| `-o`   | OUTPUT, POSTROUTING                |

**Recomendación**: Validar que la interfaz exista (ej: `ip link show`).

---

## Regla especial para el comando `-P`

- Solo puede usarse en la tabla `filter`
- Solo válido para cadenas integradas:
- INPUT
- OUTPUT
- FORWARD
- No debe usarse en otras tablas ni con otras cadenas

---
