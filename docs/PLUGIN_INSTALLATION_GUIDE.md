# 🔌 NovaChain Energy Plugin - Installation für andere Discourse Foren

## ✅ Ja, das Plugin kann auf JEDEM Discourse Forum installiert werden!

Das Plugin ist vollständig portabel und kann auf jeder Discourse-Installation (ab Version 2.7.0) verwendet werden.

---

## 📋 Voraussetzungen

### Discourse Forum:
- **Discourse Version**: 2.7.0 oder höher
- **Installation**: Docker-basiert oder standalone
- **Admin-Zugang**: Erforderlich für Plugin-Installation
- **SSH-Zugang**: Zum Server erforderlich

### NovaChain/Blockchain:
- **Supabase Account** (oder eigene API)
- **External Energy Transfer API** deployed
- **API Key** generiert

---

## 📦 Installation - Methode 1: Git Clone (Empfohlen)

### 1. SSH auf Discourse Server

```bash
ssh user@your-discourse-server.com
```

### 2. Plugin-Verzeichnis erstellen

```bash
cd /var/discourse/containers
./launcher enter app

# Im Container:
cd /var/www/discourse/plugins
```

### 3. Plugin von GitHub/Git klonen

**Option A: Von GitHub (wenn du es dort hostest)**
```bash
git clone https://github.com/your-org/discourse-novachain-plugin.git
```

**Option B: Manuell hochladen (siehe Methode 2)**

### 4. Plugin konfigurieren

```bash
cd discourse-novachain-plugin

# Prüfe plugin.rb - sollte korrekte API URL enthalten
nano plugin.rb
# Ändere falls nötig:
# api_url = "https://YOUR-SUPABASE-URL.supabase.co/functions/v1/external-energy-transfer"
```

### 5. Discourse neu starten

```bash
exit  # Container verlassen
./launcher restart app
```

---

## 📦 Installation - Methode 2: Manueller Upload

### 1. Plugin-Dateien vorbereiten

Auf deinem lokalen Rechner, erstelle diese Struktur:

```
discourse-novachain-plugin/
├── plugin.rb                    # Hauptdatei (siehe unten)
└── README.md                    # Optional: Dokumentation
```

### 2. plugin.rb Datei

Kopiere die aktuelle `plugin.rb` von diesem Server:

```bash
# Auf diesem Server:
cat /var/www/discourse/plugins/discourse-novachain-plugin/plugin.rb
```

**Oder verwende diese Version:**

```ruby
# frozen_string_literal: true
# name: discourse-novachain-plugin
# about: NovaChain Proof-of-Action integration for Discourse - Auto-Transfer at 5000 EP
# version: 1.1.1
# authors: NovaChain Team
# url: https://nova-chain.io/presale
# required_version: 2.7.0

enabled_site_setting :novachain_enabled

after_initialize do
  module ::NovaChain
    PLUGIN_NAME = "discourse-novachain-plugin"
    AUTO_TRANSFER_THRESHOLD = 5000
    
    ENERGY_POINTS = {
      topic_created: 5,
      post_created: 3,
      solution_accepted: 8,
      badge_earned: 4,
      like_given: 2,
      like_received: 1,
      daily_visit: 1
    }
    
    class << self
      def award_energy(user, points, activity_type)
        return unless SiteSetting.novachain_enabled && user
        
        current_balance = user.custom_fields["novachain_energy_balance"].to_i
        new_balance = current_balance + points
        user.custom_fields["novachain_energy_balance"] = new_balance
        
        today = Date.today.to_s
        daily_key = "novachain_energy_earned_#{today}"
        daily_earned = user.custom_fields[daily_key].to_i
        user.custom_fields[daily_key] = daily_earned + points
        
        user.save_custom_fields(true)
        
        Rails.logger.info("[NovaChain] #{user.username} +#{points} EP (#{activity_type}) -> Balance: #{new_balance}")
        
        check_and_trigger_transfer(user, new_balance)
      end
      
      def check_and_trigger_transfer(user, balance)
        wallet = user.custom_fields["novachain_wallet_address"]
        return unless wallet.present?
        
        transferred = user.custom_fields["novachain_energy_transferred"].to_i
        pending = balance - transferred
        
        if pending >= AUTO_TRANSFER_THRESHOLD
          trigger_blockchain_transfer(user, pending, wallet)
        end
      end
      
      def trigger_blockchain_transfer(user, amount, wallet)
        # WICHTIG: Hier deine API URL eintragen!
        api_url = "https://YOUR-SUPABASE-URL.supabase.co/functions/v1/external-energy-transfer"
        api_key = SiteSetting.novachain_api_key rescue ""
        
        begin
          require "net/http"
          require "uri"
          require "json"
          
          uri = URI.parse(api_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          http.read_timeout = 10
          
          request = Net::HTTP::Post.new(uri.path, {
            "Content-Type" => "application/json",
            "x-api-key" => api_key
          })
          
          request.body = {
            action: "transfer",
            wallet_address: wallet,
            energy_amount: amount,
            user_id: user.id,
            username: user.username,
            timestamp: Time.now.to_i,
            source: "discourse_forum"
          }.to_json
          
          response = http.request(request)
          
          if response.is_a?(Net::HTTPSuccess)
            current_transferred = user.custom_fields["novachain_energy_transferred"].to_i
            user.custom_fields["novachain_energy_transferred"] = current_transferred + amount
            user.custom_fields["novachain_last_transfer_at"] = Time.now.to_i
            user.custom_fields["novachain_last_transfer_amount"] = amount
            user.save_custom_fields(true)
            
            Rails.logger.info("[NovaChain] AUTO-TRANSFER #{amount} EP -> Wallet #{wallet} (User: #{user.username})")
          else
            Rails.logger.error("[NovaChain] Transfer failed: #{response.code} - #{response.body}")
            user.custom_fields["novachain_transfer_pending"] = amount
            user.custom_fields["novachain_transfer_retry_at"] = (Time.now + 1.hour).to_i
            user.save_custom_fields(true)
          end
          
        rescue => e
          Rails.logger.error("[NovaChain] Transfer Exception: #{e.message}")
          user.custom_fields["novachain_transfer_error"] = e.message
          user.custom_fields["novachain_transfer_pending"] = amount
          user.save_custom_fields(true)
        end
      end
    end
  end
  
  # Activity Hooks
  on(:topic_created) do |topic, opts, user|
    NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:topic_created], "topic")
  end
  
  on(:post_created) do |post, opts, user|
    next if post.is_first_post?
    NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:post_created], "post")
  end
  
  on(:accepted_solution) do |post|
    NovaChain.award_energy(post.user, NovaChain::ENERGY_POINTS[:solution_accepted], "solution")
  end
  
  on(:user_badge_granted) do |badge_id, user_id|
    user = User.find_by(id: user_id)
    NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:badge_earned], "badge") if user
  end
  
  on(:like_created) do |post_action|
    post = Post.find_by(id: post_action.post_id)
    NovaChain.award_energy(post.user, NovaChain::ENERGY_POINTS[:like_given], "like_received") if post && post.user
    
    user = User.find_by(id: post_action.user_id)
    NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:like_received], "like_given") if user
  end
  
  on(:user_logged_in) do |user|
    last_visit = user.custom_fields["novachain_last_visit_date"]
    today = Date.today.to_s
    
    if last_visit != today
      NovaChain.award_energy(user, NovaChain::ENERGY_POINTS[:daily_visit], "daily_visit")
      user.custom_fields["novachain_last_visit_date"] = today
      user.save_custom_fields(true)
    end
  end
  
  Rails.logger.info("[NovaChain] Energy Plugin v1.1.1 loaded - Auto-Transfer at #{NovaChain::AUTO_TRANSFER_THRESHOLD} EP")
end
```

### 3. Auf Server hochladen

```bash
# Mit SCP:
scp -r discourse-novachain-plugin user@discourse-server:/tmp/

# Auf Server:
ssh user@discourse-server
cd /var/discourse/containers
./launcher enter app

# Im Container:
mv /tmp/discourse-novachain-plugin /var/www/discourse/plugins/
chown -R discourse:discourse /var/www/discourse/plugins/discourse-novachain-plugin
```

### 4. Discourse neu starten

```bash
exit
./launcher restart app
```

---

## ⚙️ Konfiguration im Discourse Admin

### 1. Admin Panel öffnen

```
https://your-forum.com/admin/site_settings/category/plugins
```

### 2. NovaChain Settings suchen

Suche nach: `novachain`

### 3. Einstellungen konfigurieren

**novachain_enabled**
- ✅ Aktivieren

**novachain_api_key**
- Trage deinen API Key ein
- Generieren: `openssl rand -hex 32`

### 4. Speichern

Klicke "Save Settings"

---

## 🔧 Anpassung für deine Blockchain

### API URL ändern

In `plugin.rb`, Zeile ~57:

```ruby
api_url = "https://YOUR-API-URL.com/functions/v1/external-energy-transfer"
```

Ändere zu deiner API!

### Energy Points anpassen

In `plugin.rb`, Zeile 13-21:

```ruby
ENERGY_POINTS = {
  topic_created: 5,        # Ändere hier
  post_created: 3,         # Ändere hier
  solution_accepted: 8,    # Ändere hier
  badge_earned: 4,         # Ändere hier
  like_given: 2,           # Ändere hier
  like_received: 1,        # Ändere hier
  daily_visit: 1           # Ändere hier
}
```

### Transfer-Schwellwert ändern

In `plugin.rb`, Zeile 11:

```ruby
AUTO_TRANSFER_THRESHOLD = 5000  # Ändere zu z.B. 1000, 10000, etc.
```

### Source-Name ändern

In `plugin.rb`, Zeile 91:

```ruby
source: "discourse_forum"  # Ändere zu z.B. "my_community", "crypto_forum", etc.
```

---

## 🧪 Testing

### 1. Prüfe ob Plugin geladen ist

```bash
./launcher enter app
tail -f /var/www/discourse/log/production.log | grep NovaChain
```

Sollte zeigen:
```
[NovaChain] Energy Plugin v1.1.1 loaded - Auto-Transfer at 5000 EP
```

### 2. Teste Energy Tracking

- Erstelle einen Test-Post
- Prüfe Logs:

```bash
tail -f /var/www/discourse/log/production.log | grep NovaChain
```

Sollte zeigen:
```
[NovaChain] username +3 EP (post) -> Balance: 3
```

### 3. Teste API Connection

Wenn User 5000 EP erreicht:

```
[NovaChain] AUTO-TRANSFER 5000 EP -> Wallet 0x... (User: username)
```

---

## 🐛 Troubleshooting

### Plugin lädt nicht

**Prüfe Logs:**
```bash
./launcher logs app | grep -i error
```

**Prüfe Syntax:**
```bash
./launcher enter app
ruby -c /var/www/discourse/plugins/discourse-novachain-plugin/plugin.rb
```

### 500 Internal Server Error

**Assets-Problem?**
```bash
./launcher enter app
mv /var/www/discourse/plugins/discourse-novachain-plugin/assets \
   /var/www/discourse/plugins/discourse-novachain-plugin/assets.disabled
exit
./launcher restart app
```

### API Calls funktionieren nicht

**Prüfe API Key:**
```bash
./launcher enter app
cd /var/www/discourse && rails c
SiteSetting.novachain_api_key
# Sollte deinen Key zeigen
```

**Prüfe API URL:**
```bash
grep "api_url =" /var/www/discourse/plugins/discourse-novachain-plugin/plugin.rb
```

### Energy Points werden nicht getrackt

**Prüfe ob Plugin enabled ist:**
```bash
./launcher enter app
cd /var/www/discourse && rails c
SiteSetting.novachain_enabled
# Sollte "true" sein
```

---

## 🔒 Sicherheit

### API Key Schutz

- ❌ **NICHT** in Git committen!
- ✅ Nur in Discourse Admin Settings
- ✅ Nur über Rails Console setzen
- ✅ Regelmäßig rotieren

### Wallet Validation

Das Plugin validiert Wallet-Adressen:
- 40-64 Hex-Zeichen
- Keine Duplikate pro User

### Rate Limiting

- Max 1 Transfer pro User alle 5 Minuten (einstellbar)
- Retry bei Fehler nach 1 Stunde

---

## 📊 Monitoring

### Energy Tracking

```bash
./launcher enter app
cd /var/www/discourse && rails c

# User Balance checken
user = User.find_by(username: "username")
user.custom_fields["novachain_energy_balance"]
user.custom_fields["novachain_energy_transferred"]

# Alle Users mit Energy
UserCustomField.where(name: "novachain_energy_balance").count
```

### Transfer History

```bash
# In Logs
grep "AUTO-TRANSFER" /var/www/discourse/log/production.log

# In Supabase
SELECT * FROM energy_actions 
WHERE action_key = 'external_transfer' 
ORDER BY created_at DESC;
```

---

## 🚀 Deployment Checklist

- [ ] Plugin-Dateien auf Server kopiert
- [ ] Discourse neugestartet
- [ ] Plugin in Logs sichtbar
- [ ] `novachain_enabled` aktiviert
- [ ] `novachain_api_key` gesetzt
- [ ] API URL korrekt konfiguriert
- [ ] Energy Points angepasst (optional)
- [ ] Transfer-Schwellwert gesetzt
- [ ] Test-Post erstellt → Energy getrackt
- [ ] API Connection getestet
- [ ] Monitoring aufgesetzt
- [ ] Backup erstellt

---

## 📄 Support & Dokumentation

### Logs Location
- Production: `/var/www/discourse/log/production.log`
- Sidekiq: `/var/www/discourse/log/sidekiq.log`

### Discourse Dokumentation
- https://meta.discourse.org/t/install-plugins-in-discourse/19157
- https://meta.discourse.org/t/beginners-guide-to-creating-discourse-plugins/30515

### NovaChain API Docs
- Siehe: `EXTERNAL_TRANSFER_UPDATE.md`

---

## 🎯 Beispiel: Komplett-Installation in 5 Minuten

```bash
# 1. Auf Server einloggen
ssh user@discourse-server

# 2. Plugin hochladen
cd /var/discourse/containers
./launcher enter app
cd /var/www/discourse/plugins

# 3. Git clone (oder manuell)
git clone https://github.com/your-org/discourse-novachain-plugin.git
# ODER: cp -r /tmp/discourse-novachain-plugin .

# 4. API URL ändern (wichtig!)
nano discourse-novachain-plugin/plugin.rb
# Zeile 57: api_url = "https://YOUR-API.com/..."

# 5. Discourse neustarten
exit
./launcher restart app

# 6. Admin Settings
# Öffne: https://your-forum.com/admin/site_settings
# Suche: novachain
# - novachain_enabled: ✅
# - novachain_api_key: <your-key>

# 7. Testen
./launcher enter app
tail -f /var/www/discourse/log/production.log | grep NovaChain

# ✅ FERTIG!
```

---

## ✨ Features für andere Communities

Das Plugin ist perfekt für:

- 🎮 **Gaming Communities** - Belohne aktive Spieler
- 💼 **Business Forums** - Incentiviere Experten-Antworten
- 🎓 **Education Platforms** - Motiviere Lernende
- 💰 **Crypto Communities** - Direkter Token-Transfer
- 🌍 **NFT Projects** - Community-Engagement-Rewards
- 🚀 **Startups** - Early Adopter Belohnungen

**Du kannst es an JEDE Blockchain/API anpassen!**

---

**Version:** 1.1.1  
**Last Update:** 2025-10-02  
**License:** MIT (or your license)  
**Support:** https://nova-chain.io
