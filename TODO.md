1. ~~провести работу по tmp/cpu-patch~~ (0e0ae81, 217f54a)
2. продумать тестовые/дебаг прогоны для, взять для прогона tmp/Le-Accelerator-2017-Official-Trailer-1.mp4
3. AMD AMF для Radeon: добавить в encoding plans видео-actions ветку `h264_amf` (проба одним кадром, как `Test-NvencAvailable`), порядок NVENC -> AMF -> CPU. Bundled ffmpeg 8.1 уже содержит `h264_amf`/`hevc_amf`/`av1_amf`, на Ryzen APU проверено: работает
