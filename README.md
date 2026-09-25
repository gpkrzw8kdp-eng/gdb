# Abi Orga Ideen – Gymnasium Dresden Bühlau

Zwei kleine Webseiten plus eine Datenbank:

| Datei | Zweck |
|---|---|
| `index.html` | Formular, über das Schüler:innen Ideen einreichen (Name, Klasse, Kategorie, Idee). |
| `uebersicht.html` | Übersichtsseite für das Orga-Team: alle Ideen mit Filter nach Kategorie und Klasse, Suche, CSV-Export, Abhaken und Löschen. Zugang per Zugangscode. Kann auf einer ganz anderen Website liegen. |
| `supabase-setup.sql` | Legt die Datenbank (Supabase) an. Einmal ausführen. |

Die Daten liegen nicht mehr in Netlify Forms, sondern in einer Supabase-Datenbank. Dadurch kann jede beliebige Website die Einträge anzeigen.

## Einrichtung (einmalig, ca. 10 Minuten)

1. **Supabase-Projekt anlegen**: auf <https://supabase.com> kostenlos registrieren und ein neues Projekt erstellen (Region z. B. Frankfurt).
2. **Datenbank anlegen**: im Projekt links auf **SQL Editor**, den kompletten Inhalt von `supabase-setup.sql` einfügen. Vorher in der Zeile mit `'abi-orga-2027'` einen eigenen Zugangscode eintragen. Dann **Run**.
3. **Zugangsdaten kopieren**: unter **Project Settings → API** stehen die **Project URL** und der **anon public**-Key.
4. **In beide HTML-Dateien eintragen**: in `index.html` und `uebersicht.html` ganz unten im `<script>` die beiden Zeilen `SUPABASE_URL` und `SUPABASE_ANON_KEY` ersetzen.
5. **Hochladen**:
   - `index.html` wie bisher bei Netlify (oder jedem anderen Hoster) veröffentlichen.
   - `uebersicht.html` auf die andere Website legen (beliebiger Hoster, auch ein zweiter Netlify-Drop). Die Datei ist eigenständig und braucht nur die Supabase-Zugangsdaten.

Der anon-Key darf öffentlich in der HTML-Datei stehen. Er erlaubt nur das, was in der SQL-Datei freigegeben ist: Ideen einreichen sowie mit richtigem Zugangscode Ideen abrufen, abhaken und löschen. Ein direktes Lesen der Tabelle ist gesperrt.

## Zugangscode ändern

Im Supabase SQL Editor:

```sql
update public.einstellungen set wert = 'neuer-code' where schluessel = 'zugangscode';
```

## Kategorien ändern

An drei Stellen anpassen: das `<select id="kategorie">` in `index.html`, die Liste `KATEGORIEN` in `uebersicht.html` und der `check`-Constraint in `supabase-setup.sql` (bei einer bestehenden Datenbank per `alter table`).
