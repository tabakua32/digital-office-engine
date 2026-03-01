# TZ-2.4: Voice I/O Pipeline

> **Phase**: 2 — Telegram Platform Layer
> **Priority**: P1 (покращення UX, але текстовий режим працює без голосу)
> **Sessions**: 1-2
> **Dependencies**: TZ-2.1 (core bot runtime), TZ-2.2 (media sending)
> **Verdict**: COPY 70% | ADAPT 20% | BUILD 10%
> **Architecture ref**: `docs/architecture/phase-2-telegram.md` §2.4-D

---

## 1. Мета

Додати двонаправлений голосовий інтерфейс для NanoClaw через Telegram:
- **Voice → Text (STT)**: транскрипція голосових повідомлень Whisper API
- **Text → Voice (TTS)**: озвучення відповідей агента через Piper/ElevenLabs
- **Hybrid Mode**: текст + аудіо одночасно (accessibility)

**Без цього ТЗ**: голосові повідомлення показуються як `[Voice message]` placeholder,
агент не може обробити контент. Юзери які диктують (мобільний) — відсічені.

---

## 2. Scope

### 2.1 Included (MVP)

#### A. Voice Input — Speech-to-Text

```
User sends voice message (OGG/OPUS, up to 60s)
│
├── telegram.ts (existing message:voice handler):
│   ├── getFile(file_id) → file_path on Telegram servers
│   ├── Download to temp: /tmp/voice/{message_id}.ogg
│   └── Pass to VoiceTranscriber
│
├── VoiceTranscriber (STT provider selection):
│   ├── PRIMARY: Groq Whisper API (fastest, free tier)
│   │   POST https://api.groq.com/openai/v1/audio/transcriptions
│   │   model: "whisper-large-v3"
│   │   file: voice.ogg
│   │   language: "uk"  (or auto-detect)
│   │
│   ├── FALLBACK 1: OpenAI Whisper API
│   │   POST https://api.openai.com/v1/audio/transcriptions
│   │   model: "whisper-1"
│   │
│   └── FALLBACK 2: Local whisper.cpp (privacy, no API)
│       whisper.cpp -m ggml-large-v3.bin -f voice.ogg -l uk
│
├── Result: { text: "Напиши мені статтю про AI маркетинг", language: "uk", duration_s: 5.2 }
│
├── Store in SQLite (messages table):
│   content = "[🎙 Voice] Напиши мені статтю про AI маркетинг"
│   (original voice file_id retained for replay)
│
└── Continue as regular text message in pipeline
```

```typescript
interface VoiceTranscriptionConfig {
  provider: 'groq' | 'openai' | 'local';
  api_key?: string;                     // for Groq/OpenAI
  model: string;                        // whisper-large-v3 / whisper-1
  language?: string;                    // ISO 639-1, null = auto-detect
  local_model_path?: string;            // for whisper.cpp
  max_duration_seconds: number;         // default: 300 (5 min)
  fallback_chain: ('groq' | 'openai' | 'local')[];
}

interface TranscriptionResult {
  text: string;
  language: string;
  duration_seconds: number;
  confidence?: number;
  provider_used: string;
}

class VoiceTranscriber {
  constructor(config: VoiceTranscriptionConfig);

  async transcribe(filePath: string): Promise<TranscriptionResult>;

  // Try providers in order until one succeeds
  private async tryProvider(provider: string, filePath: string): Promise<TranscriptionResult>;
}
```

#### B. Voice Output — Text-to-Speech

```
Agent generates text response
│
├── Router checks voice preference:
│   registered_groups.voice_response = 'always' | 'on_request' | 'never'
│   OR: user sent voice message → reply with voice
│
├── TextToSpeechEngine (TTS provider selection):
│   ├── PRIMARY: Piper TTS (self-hosted, free, fast)
│   │   Local binary: piper --model uk_UA-lada-medium
│   │   Input: text → Output: .wav → convert to .ogg
│   │
│   ├── OPTION: ElevenLabs (high quality, paid)
│   │   POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
│   │   model_id: "eleven_multilingual_v2"
│   │
│   └── OPTION: Google Cloud TTS (reliable, paid)
│       POST https://texttospeech.googleapis.com/v1/text:synthesize
│
├── Convert to OGG/OPUS (Telegram voice format):
│   ffmpeg -i output.wav -c:a libopus output.ogg
│
└── Send via Telegram:
    sendVoice(chatJid, ogg_buffer, { caption, message_thread_id })
```

```typescript
interface TtsConfig {
  provider: 'piper' | 'elevenlabs' | 'google';
  voice_id?: string;                   // provider-specific voice
  language: string;                    // default: 'uk'
  api_key?: string;                    // for paid providers
  piper_model_path?: string;           // for local Piper
  speed: number;                       // 0.5 - 2.0, default: 1.0
  max_text_length: number;             // default: 4096 chars
}

interface TtsResult {
  audio_buffer: Buffer;                // OGG/OPUS format
  duration_seconds: number;
  provider_used: string;
}

class TextToSpeechEngine {
  constructor(config: TtsConfig);

  async synthesize(text: string): Promise<TtsResult>;

  // Chunking for long text (>max_text_length → multiple audio files)
  async synthesizeLong(text: string): Promise<TtsResult[]>;
}
```

#### C. Hybrid Mode

```typescript
// Hybrid = send both voice + text simultaneously
// Use case: accessibility, user preference, long responses

enum VoiceResponseMode {
  NEVER = 'never',           // text only
  ON_REQUEST = 'on_request', // reply with voice if user sent voice
  ALWAYS = 'always',         // every response has voice
  HYBRID = 'hybrid',         // voice + text together
}

async function sendWithVoice(
  chatJid: string,
  text: string,
  mode: VoiceResponseMode,
  opts?: { message_thread_id?: number; userSentVoice?: boolean }
): Promise<void> {
  const shouldVoice =
    mode === 'always' ||
    mode === 'hybrid' ||
    (mode === 'on_request' && opts?.userSentVoice);

  if (shouldVoice) {
    const tts = await ttsEngine.synthesize(text);
    // Voice with caption (first 1024 chars)
    await telegramChannel.sendVoice(chatJid, tts.audio_buffer, {
      caption: text.slice(0, 200) + (text.length > 200 ? '...' : ''),
      message_thread_id: opts?.message_thread_id,
    });

    if (mode === 'hybrid' && text.length > 200) {
      // Also send full text
      await telegramChannel.sendMessage(chatJid, text, {
        message_thread_id: opts?.message_thread_id,
      });
    }
  } else {
    await telegramChannel.sendMessage(chatJid, text, {
      message_thread_id: opts?.message_thread_id,
    });
  }
}
```

#### D. Voice Settings per Group

```sql
-- Extend registered_groups table
ALTER TABLE registered_groups ADD COLUMN voice_stt_enabled INTEGER DEFAULT 1;
ALTER TABLE registered_groups ADD COLUMN voice_tts_mode TEXT DEFAULT 'on_request';
-- 'never' | 'on_request' | 'always' | 'hybrid'
ALTER TABLE registered_groups ADD COLUMN voice_language TEXT DEFAULT 'uk';
```

### 2.2 Excluded (DEFER)

- **Real-time voice streaming** (live transcription while speaking) — future
- **Voice cloning** (custom voice for agent) — ElevenLabs feature, Phase 4
- **Multi-language auto-detect** (detect language per message) — P2
- **Video message transcription** (video_note circles) — P2
- **Music/audio file transcription** — not in scope
- **Piper model training** (custom Ukrainian voice) — Phase 5

---

## 3. Acceptance Criteria

### P0 — Critical Path

- [ ] Voice message → transcription → text stored in SQLite
- [ ] Transcription shown as `[🎙 Voice] <text>` in agent context
- [ ] Agent processes transcribed text as regular message
- [ ] At least one STT provider works (Groq Whisper recommended)
- [ ] Fallback: if STT fails → `[Voice message: transcription failed]`
- [ ] voice_stt_enabled per-group toggle

### P1 — Full MVP

- [ ] TTS: agent response → voice message via sendVoice
- [ ] Voice response mode configurable per group (never/on_request/always/hybrid)
- [ ] Hybrid mode: voice + text sent together
- [ ] TTS provider: at least Piper (free) or ElevenLabs (paid)
- [ ] OGG/OPUS output format (native Telegram voice)
- [ ] Long text chunked for TTS (>4096 chars → multiple voice messages)

### P2 — Extended

- [ ] Multi-language STT (auto-detect language)
- [ ] Voice message duration tracked in analytics
- [ ] Video note (circle) transcription
- [ ] STT cost tracking (API calls per month)

---

## 4. Implementation Notes

### Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/voice/transcriber.ts` | CREATE | VoiceTranscriber class with provider chain |
| `src/voice/tts-engine.ts` | CREATE | TextToSpeechEngine class |
| `src/voice/providers/groq.ts` | CREATE | Groq Whisper STT provider |
| `src/voice/providers/openai.ts` | CREATE | OpenAI Whisper STT provider |
| `src/voice/providers/piper.ts` | CREATE | Piper TTS local provider |
| `src/voice/providers/elevenlabs.ts` | CREATE | ElevenLabs TTS provider |
| `src/channels/telegram.ts` | MODIFY | Voice download + sendVoice |
| `src/router.ts` | MODIFY | Voice response mode routing |
| `src/db.ts` | MODIFY | voice columns on registered_groups |

### Key References to Read

| File | Lines | What |
|------|-------|------|
| `docs/architecture/phase-2-telegram.md` | 459-498 | Voice I/O Pipeline spec |
| `src/channels/telegram.ts` | 150-153 | Existing voice handler (placeholder) |
| `src/index.ts` | runAgent() | Output callback for TTS integration |

### Patterns from Reference Repos

| Pattern | Source | Verdict | Usage |
|---------|--------|---------|-------|
| Groq Whisper STT | claudegram (voice integration) | COPY | API client, OGG handling |
| Local whisper.cpp | kai/piper_tts.py + local whisper | ADAPT | Local STT fallback |
| Piper TTS | kai/piper_tts.py | COPY | Self-hosted TTS |
| ElevenLabs TTS | claudegram (ElevenLabs option) | COPY | Paid TTS integration |
| Voice message download | grammY getFile() | COPY | Telegram file download |

### Risks

1. **STT latency** — Groq Whisper ~1-3s, acceptable. Local whisper.cpp 5-15s on CPU. Solution: prefer API, local as fallback only.
2. **TTS quality in Ukrainian** — Piper Ukrainian voices limited. Solution: ElevenLabs multilingual as option, Piper for free tier.
3. **File size limits** — Telegram voice: max 50MB. Solution: chunk long TTS, max 5 min per voice message.
4. **API costs** — Groq free tier (limited), OpenAI ~$0.006/min. Solution: per-group enable/disable, usage tracking.
5. **ffmpeg dependency** — Required for audio conversion. Solution: Docker image includes ffmpeg, validate on startup.

---

## 5. Testing

### Unit Tests

```typescript
describe('Voice Transcriber', () => {
  test('OGG file transcribed via Groq');
  test('fallback to OpenAI if Groq fails');
  test('fallback to local whisper if APIs fail');
  test('language auto-detect works');
  test('max duration check (reject > 5min)');
  test('result stored as [🎙 Voice] prefix in messages');
});

describe('Text-to-Speech', () => {
  test('short text synthesized to OGG');
  test('long text chunked into multiple audio files');
  test('Piper local provider works');
  test('ElevenLabs API provider works');
  test('output format is OGG/OPUS');
});

describe('Hybrid Mode', () => {
  test('mode=never → text only');
  test('mode=on_request + voice input → voice reply');
  test('mode=on_request + text input → text reply');
  test('mode=always → voice for every response');
  test('mode=hybrid → voice + text together');
});
```

### Integration Tests

```typescript
describe('Voice pipeline E2E', () => {
  test('user sends voice → transcribe → agent processes → text reply');
  test('user sends voice → transcribe → agent processes → voice reply');
  test('voice message with caption → caption appended to transcription');
  test('voice disabled per group → placeholder only');
});
```

---

## 6. Definition of Done

- [ ] Всі P0 acceptance criteria пройдені
- [ ] Voice message → text transcription works (at least 1 provider)
- [ ] Transcription stored in SQLite, visible in agent context
- [ ] voice_stt_enabled toggle works per group
- [ ] TTS generates valid OGG/OPUS files
- [ ] No regression in existing tests
- [ ] TypeScript compiles without errors

---

_Cross-references: TZ-2.1 (core bot), TZ-2.2 (media sending), TZ-2.3 (streaming for voice responses)_
