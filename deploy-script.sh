#!/bin/bash

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Iniciando deploy do site Mia Goth..."

# Configurações
REPO_URL="https://github.com/viniruggeri/fanmade-goth.git"
SITE_DIR="/var/www/html/mia-goth"
DOMAIN="mia-goth.local" # Altere para seu domínio se necessário

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}


# Verificar se está no Ubuntu/Debian
if ! command -v apt &> /dev/null; then
    error "Este script foi feito para Ubuntu/Debian. Para CentOS/RHEL, use yum/dnf."
    exit 1
fi

log "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependências necessárias
log "Instalando dependências (Git, Apache2, curl)..."
sudo apt install git apache2 curl ufw -y

log "Verificando Apache2..."
if ! systemctl is-active --quiet apache2; then
    log "Iniciando Apache2..."
    sudo systemctl start apache2
    sudo systemctl enable apache2
else
    success "Apache2 já está rodando!"
fi

# Remover site padrão do Apache se existir
if [ -f "/var/www/html/index.html" ]; then
    log "Removendo página padrão do Apache..."
    sudo rm -f /var/www/html/index.html
fi

# Configurar diretório do site
log "Configurando diretório do site..."
sudo rm -rf $SITE_DIR 2>/dev/null || true
sudo mkdir -p $SITE_DIR

# Clonar repositório do GitHub
log "Clonando repositório do GitHub..."
cd /tmp
rm -rf fanmade-goth 2>/dev/null || true
git clone $REPO_URL
cd fanmade-goth

# Copiar arquivos para diretório web
log "Copiando arquivos para o servidor web..."
sudo cp -r * $SITE_DIR/
sudo chown -R www-data:www-data $SITE_DIR
sudo chmod -R 755 $SITE_DIR

# Criar configuração do Apache2
log "Configurando Apache2..."
sudo tee /etc/apache2/sites-available/mia-goth.conf > /dev/null << EOF
<VirtualHost *:80>
    ServerName _
    DocumentRoot $SITE_DIR
    
    # Logs específicos do site
    ErrorLog \${APACHE_LOG_DIR}/mia-goth.error.log
    CustomLog \${APACHE_LOG_DIR}/mia-goth.access.log combined
    
    # Cache para arquivos estáticos
    <LocationMatch "\.(css|js|jpg|jpeg|png|gif|ico|svg)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 month"
        Header append Cache-Control "public"
    </LocationMatch>
    
    # Habilitar compressão
    <Location />
        SetOutputFilter DEFLATE
        SetEnvIfNoCase Request_URI \.(?:gif|jpg|jpeg|png)$ no-gzip dont-vary
        SetEnvIfNoCase Request_URI \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
    </Location>
    
    # Configurações de segurança
    <Directory $SITE_DIR>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Habilitar módulos necessários do Apache2
log "Habilitando módulos do Apache2..."
sudo a2enmod expires
sudo a2enmod headers
sudo a2enmod deflate

# Habilitar o site
log "Habilitando site..."
sudo a2ensite mia-goth.conf
sudo a2dissite 000-default.conf

# Testar configuração do Apache2
log "Testando configuração do Apache2..."
if sudo apache2ctl configtest; then
    success "Configuração do Apache2 está OK!"
else
    error "Erro na configuração do Apache2!"
    exit 1
fi

# Reiniciar Apache2
log "Reiniciando Apache2..."
sudo systemctl reload apache2

# Configurar firewall
log "Configurando firewall..."
sudo ufw --force enable
sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'

# Verificar se o site está funcionando
log "Verificando se o site está funcionando..."
sleep 3

if curl -s http://localhost | grep -q "Mia Goth"; then
    success "Site está funcionando!"
else
    warning "Verificando possíveis problemas..."
    sudo tail -5 /var/log/apache2/mia-goth.error.log 2>/dev/null || echo "Nenhum erro encontrado nos logs"
fi

# Obter IP público da VM
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "IP não detectado")
PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Mostrar informações finais
echo ""
echo "=============================================="
success "DEPLOY CONCLUÍDO COM SUCESSO! 🎉"
echo "=============================================="
echo ""
echo "🌐 Site disponível em:"
echo "   http://localhost/ (localmente na VM)"
echo "   http://$PRIVATE_IP/ (rede local)"
if [ "$PUBLIC_IP" != "IP não detectado" ]; then
    echo "   http://$PUBLIC_IP/ (internet - se firewall permitir)"
fi
echo ""
echo "📁 Arquivos do site em: $SITE_DIR"
echo "📋 Logs do Apache em: /var/log/apache2/mia-goth.*"
echo ""
echo "🔧 Para atualizações futuras, execute:"
echo "   cd /tmp && rm -rf fanmade-goth"
echo "   git clone $REPO_URL && cd fanmade-goth"
echo "   sudo cp -r * $SITE_DIR/ && sudo systemctl reload apache2"
echo ""
success "Deploy finalizado!"
echo ""
echo "📁 Arquivos do site em: /var/www/html/mia-goth"
echo "📋 Logs do Apache2:"
echo "   Access: /var/log/apache2/mia-goth.access.log"
echo "   Error:  /var/log/apache2/mia-goth.error.log"
echo ""
echo "🔧 Comandos úteis:"
echo "   sudo systemctl status apache2   # Status do Apache2"
echo "   sudo apache2ctl configtest      # Testar configuração"
echo "   sudo systemctl reload apache2   # Recarregar configuração"
echo ""
echo "🔒 Para HTTPS (opcional):"
echo "   sudo apt install certbot python3-certbot-apache"
echo "   sudo certbot --apache -d seu-dominio.com"
echo ""