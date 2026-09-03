---
name: noctua-app-release
description: Use when building, uploading, or releasing the noctua-mobile app to TestFlight / App Store Connect, or publishing an OTA update — EAS iOS build, submit to App Store Connect, distributing a build to TestFlight groups (internal auto + external beta review), and eas update (OTA). Triggers on "subir la app", "compilar la app", "TestFlight", "App Store Connect", "release the mobile app", "beta testers", "OTA", "eas update", "publicar un update".
---

# Noctua — Release de la app mobile (EAS → App Store Connect → TestFlight)

Runbook end-to-end para compilar `noctua-mobile`, subirla a App Store Connect y distribuirla a los grupos de TestFlight. Se corre desde **taz** (`~/Developer/noctua-mobile`). Cuenta Expo owner **`blusita`**.

## ⚡ Primero: ¿OTA o build? (desde 2026-09-03)

La app usa `expo-updates` (runtimeVersion **fingerprint**, channel `production`).
Antes de compilar nada, clasificar el cambio:

- **Solo JS/TS/assets** (la mayoría de los fixes) → **OTA, sin build ni review**:
  ```bash
  cd ~/Developer/noctua-mobile && bash -ic 'eas update --channel production --environment production --message "<qué cambió>" --non-interactive'
  ```
  - `--environment production` es **obligatorio**: `EXPO_PUBLIC_API_URL` vive en
    los environments de EAS (creados 2026-09-03, production y preview); sin él
    el bundle sale apuntando a `localhost:8787` (el fallback de `api/client.ts`).
  - El teléfono lo baja en background al abrir la app y lo **aplica en el
    launch siguiente** (abrir-cerrar-abrir para verlo ya).
  - Verificar: el comando imprime el update group + fingerprint; cotejar el
    fingerprint contra el del build vigente (`eas update:list --branch production`
    y el dashboard de expo.dev). Si el fingerprint NO coincide con el del build
    instalado, el update no llega a nadie → es un cambio nativo encubierto: build.
  - Primer build con OTA: **48** (el 47 falló por fingerprint mismatch, ver
    abajo). Builds ≤46 no tienen `expo-updates` y no reciben nada.
  - Verificación estándar post-publish: `eas build:list --platform ios --limit 1
    --json` → `runtimeVersion` debe ser EXACTAMENTE el "Runtime version" que
    imprimió `eas update`. Validado 2026-09-03: build 48 y baseline OTA ambos
    `e9b1e867...`.
  - Si un build falla en la fase `CONFIGURE_EXPO_UPDATES` con "Runtime version
    mismatch": el builder calcula el fingerprint DESPUÉS del prebuild (ve `ios/`
    generado) y algunos paquetes bajan binarios en pod install
    (react-native-audio-api). El fix vive en `.fingerprintignore` del repo — el
    diff del log del build dice qué path nuevo agregar. Los logs de fase se
    bajan con GraphQL (`builds{byId{logFiles}}` + `curl --compressed`, son NDJSON).
- **Cambio nativo** (dependencia con código nativo, config plugin, permisos,
  upgrade de SDK — todo lo que cambie el fingerprint) → build + TestFlight
  (pasos 1-3 de abajo). Publicar updates OTA no consume cuota de builds; el
  plan Free de EAS Update (1k MAU) sobra.

## 0) Prerrequisitos / auth (importante)

- **Token de Expo:** `EXPO_TOKEN` está exportado en **`~/.bashrc`**, pero el shell no-interactivo NO lo sourcea → **correr TODOS los comandos de `eas` con `bash -ic '...'`**. Verificar: `bash -ic 'cd ~/Developer/noctua-mobile && eas whoami'` → `blusita (authenticated using EXPO_TOKEN)`.
- **ASC API key (para submit y para la API de grupos):** el `.p8` vive en `~/.keys/AuthKey_5W676Z4GQ9.p8` (y `~/AuthKey_5W676Z4GQ9.p8`). El `eas.json` la espera en `credentials/asc-key.p8` (gitignoreada) → **copiarla antes del submit**:
  `cp ~/.keys/AuthKey_5W676Z4GQ9.p8 ~/Developer/noctua-mobile/credentials/asc-key.p8`
- `eas.json` perfil **`production`**: `autoIncrement`, `appVersionSource: remote`, env `EXPO_PUBLIC_API_URL=https://noctua-backend-dev.blusa.cloud` (backend dev). Bundle `com.noctua.mobile`.

## 1) Build (EAS cloud, iOS)

> **Cuota:** el plan Free tiene un tope mensual de builds iOS. Al agotarse, el
> build falla con `Error: build command failed` y el mensaje "used its iOS builds
> from the Free plan this month, which will reset in N days". No es un problema
> técnico: hay que esperar al reset o cambiar de plan. Visto el 2026-07-30.

```bash
cd ~/Developer/noctua-mobile && bash -ic 'eas build -p ios --profile production --non-interactive'
```
- Usa credenciales de firma **remotas de EAS** (no pide nada). Auto-incrementa el buildNumber. ~15-20 min; devuelve el `.ipa` y el build ID. Correr en background (`run_in_background`) y esperar la notificación.

## 2) Submit a App Store Connect

> **Empezar por el bypass con `asc`.** `eas submit` se colgó en 2 de 2 intentos
> (build 21 el 2026-07-16 y build 22 el 2026-07-29): proceso vivo >25 min, sin
> output, y el build NUNCA llegó a ASC. El bypass sube en segundos. Recomendado:
>
> ```bash
> # el .ipa sale del artifact que imprime el build
> curl -sL -o /tmp/noctua.ipa "<url del artifact de EAS>"
> asc builds upload --app 6788178267 --ipa /tmp/noctua.ipa
> ```
> Después seguir con el paso 3 normal (Apple procesa ~5 min hasta VALID).
> Si se usó `eas submit` y quedó colgado, matar el proceso y hacer esto mismo.

### Alternativa: `eas submit` (histórico, propenso a colgarse)

```bash
cd ~/Developer/noctua-mobile && bash -ic 'eas submit -p ios --profile production --latest --non-interactive'
```
- `--latest` agarra el build recién hecho. Sube a ASC; Apple lo **procesa 5-10 min** → queda `processingState: VALID`. Requiere `credentials/asc-key.p8` presente (paso 0).

## 3) Distribuir a los grupos de TestFlight (App Store Connect API)

`eas` NO maneja grupos → se usa la **ASC API** (JWT ES256 con la `.p8`). Helper reutilizable (`uv run --with "pyjwt[crypto]" --with requests`, corriendo desde `~/Developer/noctua-mobile`):

```python
import time, jwt, requests
KEY_ID="5W676Z4GQ9"; ISSUER="69a6de84-2954-47e3-e053-5b8c7c11a4d1"; APP="6788178267"
def api():
    key=open("credentials/asc-key.p8").read()
    tok=jwt.encode({"iss":ISSUER,"iat":int(time.time()),"exp":int(time.time())+1000,"aud":"appstoreconnect-v1"},
                   key, algorithm="ES256", headers={"kid":KEY_ID})
    return {"Authorization":f"Bearer {tok}","Content-Type":"application/json"}, "https://api.appstoreconnect.apple.com"
```

**Grupos (fijos):** `"Internal Auto"` interno id `17e72786-8afa-4403-bac2-1b2f8e0020bf` · `"Beta Externa"` externo id `b2030bef-78c1-44b8-8e04-204314c9e16a`.

### 3a) Internos — automático (nada que hacer)
El grupo interno **auto-distribuye** todos los builds VALID. Asignar un build a mano da **422 "Builds cannot be assigned to this internal group"** — es esperado; los internos ya lo reciben ni bien queda VALID.

### 3b) Externos — Beta Review **y** asignación explícita al grupo

**El review aprobado NO entrega el build.** Son dos pasos, y saltarse el segundo
es invisible: la API muestra `betaReviewState: APPROVED` y el tester igual sigue
viendo el build viejo. Pasó (2026-08-15): los externos quedaron clavados en el
build 20 mientras el 21..31 se aprobaban uno tras otro.

`hasAccessToAllBuilds` **no sirve para grupos externos**. El grupo interno lo
tiene en `true` y por eso toma todo solo; en un grupo externo el atributo vuelve
`None`, y crear un grupo nuevo pasándolo en `true` tampoco funciona (Apple
responde 201 y lo ignora). Tiene sentido: un externo no puede recibir builds
automáticamente porque cada uno debe pasar Beta Review primero. **No perder
tiempo buscando automatizarlo por ahí.**

Después de enviar a review, asignar el build al grupo:

```python
H,B = api(); GRUPO="b2030bef-78c1-44b8-8e04-204314c9e16a"  # Beta Externa
r = requests.post(f"{B}/v1/betaGroups/{GRUPO}/relationships/builds",
                  headers=H, json={"data":[{"type":"builds","id":BUILD}]})
print(r.status_code)  # 204 = asignado
```

Verificar SIEMPRE desde el grupo, no desde el build (la relación
`/v1/builds/{id}/betaGroups` devuelve vacío aunque esté todo bien — no sirve
para comprobar nada):

```python
requests.get(f"{B}/v1/betaGroups/{GRUPO}/builds",
             params={"fields[builds]":"version"}, headers=H).json()
```

Los pasos del review (metadata obligatoria):
1. **Export compliance:** EAS lo setea (`usesNonExemptEncryption=false`). Verificar en el build.
2. **"What to Test":** PATCH `betaBuildLocalizations` del build → `whatsNew` (obligatorio).
3. **Beta App Review Info** (a nivel app, se guarda entre builds): PATCH `betaAppReviewDetails/{id}` (id de `GET /v1/apps/{APP}/betaAppReviewDetail`):
   - Contacto: `contactFirstName=Pablo, contactLastName=Pusiol, contactEmail=pablo.pusiol@gmail.com, contactPhone="+1 650 6462460"`.
   - **Cuenta demo (la app pide login → si no, Apple rechaza):** `demoAccountRequired=true, demoAccountName="demo", demoAccountPassword="demodemo"`.
4. **Enviar a review:** POST `/v1/betaAppReviewSubmissions` con `relationships.build` = el build id → `betaReviewState: WAITING_FOR_REVIEW`. Apple revisa **~24h la primera vez** (después es rápido); al aprobar, los del grupo "Beta Externa" lo reciben solos.

Snippet del flujo externo completo (build id = del paso 2):
```python
H,B = api(); BUILD="<build-id>"
# what to test
lid=requests.get(f"{B}/v1/builds/{BUILD}/betaBuildLocalizations",headers=H).json()["data"][0]["id"]
requests.patch(f"{B}/v1/betaBuildLocalizations/{lid}",headers=H,json={"data":{"type":"betaBuildLocalizations","id":lid,"attributes":{"whatsNew":"Novedades para probar: ..."}}})
# contacto + cuenta demo
did=requests.get(f"{B}/v1/apps/{APP}/betaAppReviewDetail",headers=H).json()["data"]["id"]
requests.patch(f"{B}/v1/betaAppReviewDetails/{did}",headers=H,json={"data":{"type":"betaAppReviewDetails","id":did,"attributes":{
  "contactFirstName":"Pablo","contactLastName":"Pusiol","contactEmail":"pablo.pusiol@gmail.com","contactPhone":"+1 650 6462460",
  "demoAccountRequired":True,"demoAccountName":"demo","demoAccountPassword":"demodemo"}}})
# submit a review
r=requests.post(f"{B}/v1/betaAppReviewSubmissions",headers=H,json={"data":{"type":"betaAppReviewSubmissions","relationships":{"build":{"data":{"type":"builds","id":BUILD}}}}})
print(r.status_code, r.json().get("data",{}).get("attributes") or r.text[:200])
```

### Consultar estado (read-only)
```python
H,B=api()
# builds recientes
for b in requests.get(f"{B}/v1/builds",params={"filter[app]":APP,"limit":5,"sort":"-version","fields[builds]":"version,processingState,expired"},headers=H).json()["data"]:
    print(b["attributes"]["version"], b["attributes"]["processingState"], b["id"])
# estado de review de un build
s=requests.get(f"{B}/v1/builds/{BUILD}/betaAppReviewSubmission",headers=H).json().get("data")
print(s["attributes"]["betaReviewState"] if s else "sin review")
```

## Gotchas

- `eas` sin `bash -ic` → "Not logged in" (no toma `EXPO_TOKEN` del `.bashrc`).
- Submit sin `credentials/asc-key.p8` → falla; copiarla de `~/.keys/`.
- El POST de asignar build a grupo devuelve 204 pero **no persiste para externos** hasta que se envía a Beta Review con toda la metadata (contacto + whatsNew + compliance). Para internos, el 422 es normal (auto).
- Sin cuenta demo, Apple rechaza el review externo (la app pide login). Cargarla en `betaAppReviewDetail` (`demo`/`demodemo`).
- Review externo ~24h la 1ra vez. Los **internos NO esperan** — build 20+ les llega ni bien queda VALID.
- **`eas submit` clavado en "Submitting"** (visto 2026-07-16, build 21: dos submissions >1h en `IN_QUEUE`, sin incidente en status.expo.dev): verificar server-side con GraphQL
  `curl -H "Authorization: Bearer $EXPO_TOKEN" -d '{"query":"query{submissions{byId(submissionId:\"<id>\"){status error{message} updatedAt}}}"}' https://api.expo.dev/graphql`
  (el id sale del link "Submission details"). Si sigue `IN_QUEUE` con `updatedAt` == `createdAt` tras ~10 min: cancelar (mutación `submission{cancelSubmission(submissionId:...)}`) y **bypass con asc**: bajar el `.ipa` del artifact de EAS y `asc builds upload --app 6788178267 --ipa <archivo>` — sube en segundos y Apple lo procesa igual (~5 min a VALID). Después seguir con el paso 3 normal.

Ver también la memoria `eas-mobile-build-testflight` y la skill `fleet` (SSH/deploy).

## 1-bis) Build LOCAL en Buster (bypass de la cuota Free — validado 2026-08-24)

Cuando la cuota iOS del plan Free está agotada, el build se hace en la MacBook
(Buster, `blusa@100.77.231.63`, clave de Taz autorizada) con `eas build --local`:
mismas credenciales remotas de EAS, cero costo, ~10 min.

Requisitos ya instalados en Buster: Xcode + **plataforma iOS** (si falta:
`xcodebuild -downloadPlatform iOS`, ~8.5 GB — el error es "iOS X.Y is not
installed"), fastlane (brew), CocoaPods, node. Repo en `~/Developer/noctua-mobile`
(SIN acceso a GitHub por SSH no-interactivo — el agente 1Password no está: se
actualiza con `git bundle` desde Taz + `git pull /tmp/noctua-mobile.bundle main`).
Token: `~/.expo-token.env` en Buster (copiado del EXPO_TOKEN de Taz).

```bash
ssh blusa@100.77.231.63 'zsh -lc "source ~/.expo-token.env; cd ~/Developer/noctua-mobile && \
  nohup npx --yes eas-cli build -p ios --profile production --local --non-interactive \
  --output ~/noctua-cry.ipa > ~/eas-local-build.log 2>&1 & echo pid:\$!"'
```

- `nohup` + log: sobrevive al corte de SSH; vigilar el log o la aparición del .ipa.
- Los warnings de "Unable to load simulator devices" son ruido; el error real
  de plataforma faltante dice "Unable to find a destination ... not installed".
- No hizo falta desbloquear keychain (fastlane usa uno temporal propio).
- Después: `scp` del .ipa a Taz y seguir con el paso 2 (`asc builds upload`).
- El buildNumber lo asigna EAS igual que en la nube (appVersionSource remote).
- Tras varios reviews aprobados, Apple aprueba el Beta Review casi al instante;
  si el POST de submission da `INVALID_QC_STATE`, chequear primero si YA está
  `APPROVED` (build `betaAppReviewSubmission`) antes de reintentar.
- Buster queda siempre accesible: `sudo pmset -c sleep 0` (corriente) + dock.

### Gotcha crítico: identificar el build por VERSIÓN, nunca por "el más reciente"

Visto 2026-08-31: `sort=-uploadedDate`/`-version` con `limit` chico agarró un
build VIEJO ya-VALID y todo el flujo externo (whatsNew, asignación, review) se
aplicó al build equivocado — el interno auto-distribuyó el correcto y la
discrepancia quedó invisible hasta que el tester la notó. Regla:
1. Leer el buildNumber REAL del .ipa antes de subir:
   `python3 -c "import zipfile,plistlib;z=zipfile.ZipFile('X.ipa');print(plistlib.loads(z.read([n for n in z.namelist() if n.endswith('.app/Info.plist')][0]))['CFBundleVersion'])"`
2. Esperar/buscar en ASC con `filter[version]=<ese número>` (puede tardar
   varios minutos en aparecer tras el "Upload committed" del asc CLI).
3. El id de build en ASC coincide con el uploadId que devuelve `asc builds
   upload` — sirve de doble verificación.
