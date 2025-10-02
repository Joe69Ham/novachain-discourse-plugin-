# ⚡ NovaChain Energy Plugin for Discourse

> Belohne deine Community automatisch mit Blockchain-Rewards!

[![Version](https://img.shields.io/badge/version-1.1.1-brightgreen.svg)](https://github.com/novachain/discourse-plugin)
[![Discourse](https://img.shields.io/badge/discourse-2.7.0%2B-blue.svg)](https://www.discourse.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-stable-success.svg)]()

Ein leistungsstarkes Discourse-Plugin, das User-Aktivitäten automatisch mit Energy Points belohnt und bei Erreichen eines konfigurierbaren Schwellwerts automatisch auf Blockchain-Wallets transferiert.

## 🎯 Features

- ⚡ **Automatisches Tracking** - Posts, Topics, Likes, Badges → Energy Points
- 🔄 **Auto-Transfer** - Bei 5000 EP automatischer Transfer auf User-Wallet
- 🔧 **Vollständig anpassbar** - Energy-Werte, Schwellwerte, API-URLs
- 🌍 **Universell einsetzbar** - Funktioniert mit jeder Blockchain/API
- 🔒 **Sicher & Stabil** - Produktionsreif mit vollständigem Error-Handling
- 📊 **Monitoring** - Vollständiges Logging aller Transaktionen

## 📊 Energy Points System (Default)

| Aktivität | Energy Points |
|-----------|---------------|
| Topic erstellen | +5 EP |
| Post erstellen | +3 EP |
| Solution accepted | +8 EP |
| Badge erhalten | +4 EP |
| Like vergeben | +2 EP |
| Like erhalten | +1 EP |
| Täglicher Login | +1 EP |

**Auto-Transfer:** Bei 5000 EP automatisch auf Wallet

## 🚀 Quick Start

### 1. Download

```bash
wget https://nova-chain.io/downloads/discourse-novachain-plugin-v1.1.1.tar.gz
```

### 2. Installation

```bash
# Entpacken
tar -xzf discourse-novachain-plugin-v1.1.1.tar.gz

# Auf Server kopieren
scp -r discourse-novachain-plugin user@server:/var/www/discourse/plugins/

# Discourse neustarten
cd /var/discourse
./launcher restart app
```

### 3. Konfiguration

1. **Admin Panel** öffnen: `https://your-forum.com/admin/site_settings`
2. Nach `novachain` suchen
3. **Settings konfigurieren:**
   - `novachain_enabled`: ✅ Aktivieren
   - `novachain_api_key`: Dein API Key

### 4. API URL anpassen

In `plugin.rb` Zeile 57:
```ruby
api_url = "https://YOUR-API-URL.com/functions/v1/external-energy-transfer"
```

## 📋 Voraussetzungen

- **Discourse:** Version 2.7.0 oder höher
- **Ruby:** Version 3.0+
- **Installation:** Docker oder Standalone
- **API:** Blockchain API mit Energy Transfer Endpoint

## 🔧 Anpassung

### Energy Points ändern

In `plugin.rb`, Zeile 13-21:
```ruby
ENERGY_POINTS = {
  topic_created: 10,      # Default: 5
  post_created: 5,        # Default: 3
  solution_accepted: 15,  # Default: 8
  # ...
}
```

### Transfer-Schwellwert ändern

In `plugin.rb`, Zeile 11:
```ruby
AUTO_TRANSFER_THRESHOLD = 10000  # Default: 5000
```

### Source-Name ändern

In `plugin.rb`, Zeile 91:
```ruby
source: "my_community"  # Default: "discourse_forum"
```

## 🌍 Kompatibilität

- ✅ Discourse 2.7.0+
- ✅ Docker Installation
- ✅ Standalone Installation  
- ✅ DigitalOcean, AWS, Hetzner
- ✅ Self-Hosted & Managed Discourse

## 🎯 Use Cases

- 🎮 **Gaming Communities** - Belohne aktive Spieler
- 💰 **Crypto Communities** - Direkter Token-Transfer
- 🎓 **Education Platforms** - Motiviere Lernende
- 🌍 **NFT Projects** - Community-Engagement-Rewards
- 💼 **Business Forums** - Incentiviere Experten
- 🚀 **Startups** - Early Adopter Belohnungen

## 📚 Dokumentation

- [📖 Installation Guide](PLUGIN_INSTALLATION_GUIDE.md) - Vollständige Schritt-für-Schritt Anleitung
- [🔧 API Integration](EXTERNAL_TRANSFER_UPDATE.md) - API Setup & Testing
- [⚡ Quick Reference](QUICK_REFERENCE.txt) - Schnellreferenz für Commands

## 🧪 Testing

### Plugin-Status prüfen

```bash
./launcher enter app
tail -f /var/www/discourse/log/production.log | grep NovaChain
```

Sollte zeigen:
```
[NovaChain] Energy Plugin v1.1.1 loaded - Auto-Transfer at 5000 EP
```

### Energy Tracking testen

Erstelle einen Test-Post und prüfe Logs:
```bash
tail -f /var/www/discourse/log/production.log | grep NovaChain
```

Output:
```
[NovaChain] username +3 EP (post) -> Balance: 3
```

### API Connection testen

Bei 5000 EP sollte erscheinen:
```
[NovaChain] AUTO-TRANSFER 5000 EP -> Wallet 0x... (User: username)
```

## 🐛 Troubleshooting

### Plugin lädt nicht

```bash
# Logs prüfen
./launcher logs app | grep -i error

# Syntax prüfen
./launcher enter app
ruby -c /var/www/discourse/plugins/discourse-novachain-plugin/plugin.rb
```

### 500 Internal Server Error

Assets-Problem? Deaktiviere sie:
```bash
./launcher enter app
mv /var/www/discourse/plugins/discourse-novachain-plugin/assets \
   /var/www/discourse/plugins/discourse-novachain-plugin/assets.disabled
exit
./launcher restart app
```

### API Calls funktionieren nicht

```bash
# API Key prüfen
./launcher enter app
cd /var/www/discourse && rails c
SiteSetting.novachain_api_key  # Sollte deinen Key zeigen
```

## 📊 Monitoring

### User Balance checken

```ruby
user = User.find_by(username: "username")
user.custom_fields["novachain_energy_balance"]
user.custom_fields["novachain_energy_transferred"]
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

## 🔒 Sicherheit

- ❌ API Key **NICHT** in Git committen
- ✅ Nur in Discourse Admin Settings
- ✅ Regelmäßig rotieren
- ✅ Wallet-Validation (40-64 Hex-Zeichen)
- ✅ Rate Limiting & Retry Logic

## 🤝 Support

- 🌐 [Community Forum](https://community.nova-chain.io)
- 💬 [Discord](https://discord.gg/novachain)
- 📧 [Email Support](mailto:support@nova-chain.io)
- 🐛 [Issue Tracker](https://github.com/novachain/discourse-plugin/issues)

## 📝 Changelog

### v1.1.1 (2025-10-02)
- ✅ Stable Release
- ✅ External Energy Transfer API Integration
- ✅ Auto-Transfer bei konfigurierbarem Schwellwert
- ✅ Vollständiges Error-Handling
- ✅ Produktionsreif

### v1.1.0 (2025-10-01)
- Initial Release
- Basic Energy Tracking
- Supabase Integration

## 📄 License

MIT License - siehe [LICENSE](LICENSE) Datei

## 👥 Authors

**NovaChain Team**
- Website: [nova-chain.io](https://nova-chain.io)
- Community: [community.nova-chain.io](https://community.nova-chain.io)

## ⭐ Star History

Wenn dir dieses Plugin gefällt, gib uns einen Star! ⭐

---

**Made with ⚡ by NovaChain Team**
