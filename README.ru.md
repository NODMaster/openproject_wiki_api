# openproject_wiki_api

Плагин для [OpenProject](https://www.openproject.org/), который открывает доступ к wiki-страницам через REST API по адресу `/api/v3/wiki_api`.

Плагин создан для интеграций и ИИ-агентов, которым нужен программный доступ к вики проектов: список страниц, чтение, создание дочерних страниц и обновление — всё по обычному HTTPS с API-токенами и с теми же правами, что в веб-интерфейсе.

## Возможности

- Список wiki-страниц проекта (пагинация, сортировка по заголовку)
- Чтение страницы по ID или по slug/permalink
- Создание страниц (в том числе дочерних)
- Обновление заголовка, содержимого и родителя; optimistic locking через `lock_version`
- История страницы (journals) и HTML-diff между версиями
- Список вложений страницы со ссылками на скачивание
- Health-эндпоинт для проверки деплоя

Все операции уважают стандартные права OpenProject: `view_wiki_pages` для чтения, `edit_wiki_pages` для записи. Пользователь видит только то, что видел бы в веб-интерфейсе.

## Требования

- OpenProject 17.x (разработано и проверено на 17.6, совместимо с 17.9)
- Проект с включённым модулем **Wiki**

## Установка

Стандартная установка плагина OpenProject.

1. Скопировать каталог плагина в `modules/`:

   ```bash
   cp -r openproject_wiki_api /app/modules/openproject_wiki_api
   ```

2. Зарегистрировать gem в `Gemfile.modules`, внутри блока `group :opf_plugins do`:

   ```ruby
   gem 'openproject_wiki_api', path: 'modules/openproject_wiki_api'
   ```

3. Установить зависимости и перезапустить:

   ```bash
   bundle install
   # перезапуск приложения (например, `docker compose restart web worker cron`)
   ```

4. Проверка:

   ```bash
   curl -u apikey:<TOKEN> https://<host>/api/v3/wiki_api/health
   # => {"status":"ok","plugin":"openproject_wiki_api","version":"0.4.0"}
   ```

> **Важно для Docker.** В официальном контейнере `openproject/openproject` нет доступа к rubygems.org. **Не удаляйте и не пересоздавайте `Gemfile.lock`** — добавьте четыре записи плагина текстово (подробности в [docs/API.md](docs/API.md)), иначе `bundle install` упадёт, а web-контейнер уйдёт в цикл перезапусков.

## Использование

Аутентификация — любой **API-токен** OpenProject (профиль → Access tokens) через HTTP Basic auth с литеральным логином `apikey`:

```bash
curl -u apikey:<TOKEN> https://<host>/api/v3/wiki_api/projects/my-project/wiki_pages
```

Пример — создание страницы:

```bash
curl -u apikey:<TOKEN> -X POST \
  -H "Content-Type: application/json" \
  -d '{"title":"Встреча","text":"# Заметки\nПривет","journal_notes":"создано через API"}' \
  https://<host>/api/v3/wiki_api/projects/my-project/wiki_pages
```

Полный справочник эндпоинтов, форматы JSON и заметки о поведении: [docs/API.md](docs/API.md) (на английском).

## Особенности работы

- Содержимое страниц — **CommonMark** markdown.
- Slug (permalink) выводится из заголовка автоматически (кириллица сохраняется).
- Быстрые последовательные правки одного пользователя могут **агрегироваться** в одну версию журнала (настройка «время агрегации журнала», по умолчанию 5 минут). Для агентов: либо выдерживайте интервал между правками, либо опирайтесь на список журналов, а не на предположение «один запрос — одна версия».
- Обновления с optimistic locking: передавайте текущий `lock_version`, устаревшее значение вернёт `409`.

## 💖 Поддержать проект

Если плагин оказался полезен, вы можете поддержать его развитие любым удобным способом:

### 🌍 International Support
- **Tribute (Credit cards, Apple/Google Pay):** [Поддержать через Tribute](https://web.tribute.tg/d/Tzc)
- **USDT (TRC-20):** `TCapCF7MBhkCjjP6DoGvhLXP2ZM5sNV3S5`

### 🇷🇺 Для спонсоров из РФ и СНГ
- **DonationAlerts (Карты РФ, СБП, криптовалюта):** [donationalerts.com/r/nodmaster](https://www.donationalerts.com/r/nodmaster)
- **Tribute (Карты РФ, вывод в USDT):** [Поддержать через Tribute](https://web.tribute.tg/d/Tzc)

## Лицензия

GPLv3 — см. [LICENSE](LICENSE).

## Авторы

- NODMaster — https://github.com/NODMaster
- Kimi AI

Не аффилировано с OpenProject GmbH.
