# Gestos em Foto

Reconhecimento de três gestos de mão a partir de uma fotografia, em um app Flutter/Android. O MediaPipe Hand Landmarker localiza a mão e extrai 21 pontos (landmarks); a classificação do gesto é própria, feita por regras geométricas sobre os ângulos das articulações dos dedos.

Micro-Projeto de Visão Computacional — Capacitação em Visão Computacional · IFPE · INPaR · Financiamento FACEPE.

| Gesto | Saída | Regra |
|---|---|---|
| Palma aberta | `palma_aberta` | indicador, médio, anelar e mínimo estendidos |
| Punho fechado | `punho_fechado` | os quatro dedos dobrados |
| Paz | `paz` | indicador e médio estendidos; anelar e mínimo dobrados |
| — | `nao_reconhecido` | qualquer outro padrão, ângulo inválido ou sem mão |

> **Escopo.** É um classificador heurístico baseado em geometria, sobre um detector de landmarks pré-treinado. Não há treinamento de modelo. São três poses estáticas simplificadas; o sistema não reconhece linguagem de sinais.

## Vídeos de apresentação

- [Vídeo de apresentação (YouTube)](https://youtu.be/Ol30H8wTrKs)
- [Vídeo do Lucas (Google Drive)](https://drive.google.com/file/d/1a-Xdm_yY_wQ1hAGeCnRLN6kM31ofFAac/view)

## Sumário

1. [Visão geral da arquitetura](#1-visão-geral-da-arquitetura)
2. [Método](#2-método)
3. [Notebook de desenvolvimento e avaliação](#3-notebook-de-desenvolvimento-e-avaliação)
4. [Aplicativo Flutter/Android](#4-aplicativo-flutterandroid)
5. [Como executar](#5-como-executar)
6. [Paridade entre notebook e app](#6-paridade-entre-notebook-e-app)
7. [Limitações](#7-limitações)
8. [Dados, licença e ética](#8-dados-licença-e-ética)

## 1. Visão geral da arquitetura

O repositório tem duas partes que compartilham o mesmo contrato de classificação:

- **Notebook (Python, Google Colab):** bancada para desenvolver e avaliar as regras. Calibra o limiar e mede o desempenho no HaGRID.
- **App (Flutter + Kotlin):** reproduz as mesmas regras e a mesma matemática em Dart e mostra o gesto na tela.

Fluxo no app:

```text
Galeria ──► Flutter (image_picker)
              │ caminho da imagem
              ▼
        MethodChannel  br.edu.ifpe.mobile.mediapipe/hand_tracking
              │
              ▼
        Kotlin (MainActivity)
          ├─ extractLandmarks ─► MediaPipe HandLandmarker ─► 21 × (x, y, z) normalizados
          └─ getImageSize ─────► largura × altura do bitmap decodificado
              │
              ▼
        Dart: GestureRecognitionService
          ├─ ângulos PIP dos 4 dedos (em pixels)
          └─ regras + limiar ─► Gesture
              │
              ▼
        HomePage: gesto em texto, ângulos e lista de pontos
```

A detecção nativa e a classificação ficam separadas: o Kotlin não conhece os gestos, e o serviço de domínio em Dart não conhece o MediaPipe.

## 2. Método

### 2.1 Landmarks

O MediaPipe devolve 21 pontos por mão, com `x` e `y` normalizados em [0, 1] (relativos à largura e à altura da imagem) e `z` relativo. O app usa uma mão por imagem (`numHands = 1`).

### 2.2 Ângulo articular

Para cada dedo (exceto o polegar) mede-se o ângulo na articulação PIP, entre os segmentos B→A e B→C:

```text
θ = arccos( ((A − B) · (C − B)) / (‖A − B‖ · ‖C − B‖) )
```

| Dedo | A | B (articulação) | C |
|---|---|---|---|
| Indicador | 5 | 6 | 7 |
| Médio | 9 | 10 | 11 |
| Anelar | 13 | 14 | 15 |
| Mínimo | 17 | 18 | 19 |

**Correção de proporção.** Os pontos chegam normalizados, e os dois eixos têm escalas diferentes em imagens não quadradas. O ângulo é calculado em pixels (`px = x * largura`, `py = y * altura`). Calcular direto em x/y normalizados distorce o resultado. Por isso o app precisa da largura e da altura da imagem.

Detalhes numéricos: o cosseno é limitado a [−1, 1] antes do `arccos`; se `‖A − B‖ · ‖C − B‖ < 1e-6`, o ângulo é inválido (`null`) e o gesto é `nao_reconhecido`.

### 2.3 Regras

Um dedo está **estendido** quando `θ >= limiar` e **dobrado** caso contrário. A combinação dos quatro dedos define o gesto (tabela no início deste documento). O polegar não entra nas regras.

### 2.4 Limiar

O limiar é escolhido apenas no conjunto de calibração do notebook, testando 130°, 140°, 150°, 160° e 170°. O critério é a maior acurácia, com desempate pelo menor número de `nao_reconhecido` e depois pelo valor mais próximo de 150°. O conjunto de teste não participa dessa escolha.

No app, o limiar é a constante `kLimiarGestos` em `lib/domain/services/gesture_recognition_service.dart`. Ela deve ter o mesmo valor impresso pelo notebook em "Limiar escolhido".

## 3. Notebook de desenvolvimento e avaliação

Arquivo: `notebooks/Gestos_em_Foto.ipynb` (executa no Google Colab, sem GPU).

**Dados.** HaGRID (*HAnd Gesture Recognition Image Dataset*), classes `palm` → `palma_aberta`, `fist` → `punho_fechado`, `peace` → `paz`. O notebook baixa a amostra reduzida `cj-mills/hagrid-sample-30k-384p` do Hugging Face.

**Protocolo.**
1. Mantém só imagens com uma única mão anotada e rótulo coerente com a classe.
2. Divide as **pessoas** (`user_id`) em calibração e teste (50% cada, `SEED = 42`), sem nenhuma pessoa nos dois conjuntos.
3. Sorteia 100 imagens por classe em cada conjunto, com no máximo 2 por pessoa.
4. Extrai os landmarks e os ângulos **uma vez por imagem**; a calibração opera sobre a tabela de ângulos.
5. Escolhe o limiar na calibração e avalia o teste uma única vez.

**Avaliação.** A acurácia considera todas as imagens: falhas de detecção e `nao_reconhecido` contam como erro da classe real. O notebook reporta acurácia com intervalo de confiança de 95% (Wilson), `classification_report`, matriz de confusão com coluna extra para `nao_reconhecido`, taxa de detecção por classe e análise dos erros com os landmarks desenhados. A conclusão é gerada por código a partir dos números da execução.

**Saídas** (`saidas_gestos.zip`): `resultados_gestos.csv` (por imagem, com os ângulos), `amostra_hagrid.csv`, `regras_gestos.csv` e `contrato_flutter_dart.md`.

Os resultados vivem nas saídas do notebook executado. Este README não fixa métricas.

## 4. Aplicativo Flutter/Android

### 4.1 Estrutura

```text
lib/
├── domain/
│   ├── models/
│   │   ├── hand_point.dart                    # x, y, z normalizados
│   │   ├── image_size.dart                    # largura e altura em pixels
│   │   └── gesture.dart                       # Gesture, HandAngles, GestureResult
│   └── services/
│       ├── i_hand_tracking_service.dart       # contrato de detecção
│       └── gesture_recognition_service.dart   # ângulos, regras e limiar
├── data/
│   └── services/
│       └── mediapipe_hand_tracking_service.dart   # ponte com o Kotlin (MethodChannel)
└── presentation/
    ├── controllers/
    │   └── hand_tracking_controller.dart      # estado reativo (ValueNotifier)
    └── pages/
        └── home_page.dart                     # interface
android/app/src/main/
├── kotlin/br/edu/ifpe/mobile/prova_de_conceito/MainActivity.kt
└── assets/hand_landmarker.task                # modelo do MediaPipe
test/
└── gesture_recognition_service_test.dart
```

### 4.2 Contrato do canal nativo

Canal: `br.edu.ifpe.mobile.mediapipe/hand_tracking`.

| Método | Argumentos | Retorno |
|---|---|---|
| `extractLandmarks` | `{imagePath: String}` | lista de 21 mapas `{x, y, z}` (Double); lista vazia se não houver mão |
| `getImageSize` | `{imagePath: String}` | `{width: Int, height: Int}` do bitmap decodificado com `BitmapFactory` |

`getImageSize` lê as dimensões do mesmo arquivo que o `extractLandmarks` decodifica, então os pontos normalizados e as dimensões usadas na correção de proporção pertencem à mesma grade de pixels.

### 4.3 Serviço de domínio

`GestureRecognitionService` recebe `List<HandPoint>`, largura e altura e devolve um `GestureResult` (gesto e os quatro ângulos).

- Lista com tamanho diferente de 21, ou dimensões não positivas → `nao_reconhecido`.
- Qualquer ângulo `null`, NaN ou infinito → `nao_reconhecido`.
- `recognize`, `extractAngles`, `calculateAngle` e `classifyAngles` são puros e testáveis sem dispositivo.

### 4.4 Interface

Depois de escolher uma imagem na galeria, a tela mostra a prévia da foto, o gesto em texto (`Palma aberta`, `Punho fechado`, `Paz` ou `Gesto não reconhecido`) com o identificador do contrato, os quatro ângulos medidos e a lista dos 21 pontos. Sem mão detectada, exibe "Nenhuma mão detectada na imagem."

### 4.5 Testes

`test/gesture_recognition_service_test.dart` cobre:
- o cálculo do ângulo (180°, 90°, proporção corrigida, pontos coincidentes);
- os casos do contrato do notebook (quatro dedos estendidos, quatro dobrados, paz, só indicador, anelar e mínimo, exatamente no limiar, ângulo ausente, sem mão);
- o caminho completo de landmarks sintéticos até o gesto.

## 5. Como executar

### 5.1 Notebook

1. Abra `notebooks/Gestos_em_Foto.ipynb` no Google Colab.
2. Execute as células em ordem. O notebook instala as dependências, baixa o modelo e o dataset e gera as saídas.
3. Se o Colab pedir reinicialização da sessão após a instalação, reinicie e continue a partir da célula de imports.

### 5.2 App

Requisitos: Flutter com Dart 3, JDK 17, dispositivo **Android físico ARM64** (o app foi validado assim; o emulador não é usado). Configuração relevante do projeto: `minSdk = 24`, dependência `com.google.mediapipe:tasks-vision:0.10.14`, pacote `image_picker`.

```bash
# modelo do MediaPipe (uma vez)
mkdir -p android/app/src/main/assets
curl -L -o android/app/src/main/assets/hand_landmarker.task \
  https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task

flutter pub get
flutter test
flutter run            # com o celular conectado
```

## 6. Paridade entre notebook e app

O app deve reproduzir o notebook. Para conferir:

1. Escolha algumas linhas de `resultados_gestos.csv` e copie as imagens correspondentes (`caminho`) para o celular.
2. Abra cada imagem no app e compare os quatro ângulos e o gesto com as colunas `angulo_*` e `rotulo_previsto` do CSV.
3. Diferenças pequenas de arredondamento são esperadas. Diferenças de gesto exigem investigação.

Pontos que podem causar divergência:

- **Orientação EXIF.** O notebook aplica `ImageOps.exif_transpose` antes de detectar. O Kotlin decodifica com `BitmapFactory.decodeFile`, sem corrigir EXIF. Em fotos de câmera com rotação gravada em EXIF, a detecção e os ângulos podem diferir.
- **Redução de imagem.** O notebook reduz imagens com lado maior que 1280 px, mantendo a proporção. Os pontos são normalizados e a proporção se mantém, então o efeito é pequeno.
- **Limiar.** A constante do app precisa coincidir com a escolhida pelo notebook.

## 7. Limitações

- O polegar não entra nas regras.
- O ângulo é medido em 2D, no plano da imagem. Dedos apontados para a câmera ficam encurtados e alteram o ângulo.
- A avaliação usa uma amostra reduzida (384p) do HaGRID, com uma única mão por imagem e poses encenadas. O resultado indica desempenho nesse conjunto e não em condições gerais.
- Não há avaliação por grupo demográfico.
- Somente imagens estáticas da galeria; não há captura em tempo real.

Evoluções naturais: característica do polegar, ângulos de outras articulações (MCP e DIP) ou distância entre a ponta e a base de cada dedo, avaliação com mais imagens e correção de EXIF no lado nativo.

## 8. Dados, licença e ética

- **Dataset.** HaGRID — *HAnd Gesture Recognition Image Dataset*, de Alexander Kapitanov, Andrey Makhlyarchuk e Karina Kvanchiani. Licença CC BY-SA 4.0 (o repositório oficial a descreve como uma variante da CC BY-SA 4.0), com atribuição aos autores. A amostra reduzida `cj-mills/hagrid-sample-30k-384p` é publicada no Hugging Face com a mesma licença. Este repositório não redistribui imagens do dataset: o notebook as baixa durante a execução.
- **Modelo.** `hand_landmarker.task` é o modelo oficial do MediaPipe Hand Landmarker.
- **Privacidade.** As fotos do HaGRID mostram pessoas reais. O notebook usa apenas o rótulo e o `user_id` pseudonimizado para separar calibração e teste. As imagens ficam só na sessão do Colab, e as saídas contêm caminhos, ângulos e identificadores pseudonimizados.
- **Quem pode ser mais prejudicado.** Mãos de tons de pele, tamanhos e condições pouco representados na amostra (por exemplo, dedos com mobilidade limitada) podem ter desempenho pior. Isso exige teste próprio antes de qualquer uso real.