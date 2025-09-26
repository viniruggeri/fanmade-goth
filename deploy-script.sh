#!/bin/bash

set -e

echo "🚀 Iniciando deploy do site Mia Goth..."


log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}


if ! command -v apt &> /dev/null; then
    error "Este script foi feito para Ubuntu/Debian. Para CentOS/RHEL, use yum/dnf."
    exit 1
fi

log "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y


log "Verificando Apache2..."
if ! systemctl is-active --quiet apache2; then
    log "Instalando/iniciando Apache2..."
    sudo apt install apache2 -y
    sudo systemctl start apache2
    sudo systemctl enable apache2
else
    log "Apache2 já está rodando!"
fi

log "Configurando diretório do site..."
sudo mkdir -p /var/www/html/mia-goth
sudo chown -R $USER:$USER /var/www/html/mia-goth


if [ -d "/tmp/mia-goth-site" ]; then
    log "Copiando arquivos do site..."
    sudo cp -r /tmp/mia-goth-site/* /var/www/html/mia-goth/
else
    error "Arquivos não encontrados em /tmp/mia-goth-site/"
    echo "Execute primeiro no Windows:"
    echo "scp -r * usuario@seu-ip-da-vm:/tmp/mia-goth-site/"
    exit 1
fi

# Configurar permissões
log "Configurando permissões..."
sudo chown -R www-data:www-data /var/www/html/mia-goth
sudo chmod -R 755 /var/www/html/mia-goth

# Criar configuração do Apache2
log "Configurando Apache2..."
sudo tee /etc/apache2/sites-available/mia-goth.conf > /dev/null << EOF
<VirtualHost *:80>
    ServerName _
    DocumentRoot /var/www/html/mia-goth
    
    # Logs específicos do site
    ErrorLog \${APACHE_LOG_DIR}/mia-goth.error.log
    CustomLog \${APACHE_LOG_DIR}/mia-goth.access.log combined
    
    # Cache para arquivos estáticos
    <LocationMatch "\.(css|js|jpg|jpeg|png|gif|ico|svg)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 year"
        Header append Cache-Control "public, immutable"
    </LocationMatch>
    
    # Habilitar compressão
    <Location />
        SetOutputFilter DEFLATE
    </Location>
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
sleep 2

if curl -s http://localhost | grep -q "Mia Goth"; then
    success "Site está funcionando!"
else
    error "Problema ao acessar o site"
    echo "Verificando logs..."
    sudo tail -10 /var/log/nginx/mia-goth.error.log
fi

# Mostrar informações finais
echo ""
echo "=============================================="
success "DEPLOY CONCLUÍDO!"
echo "=============================================="
echo ""
echo "🌐 Site disponível em:"
echo "   http://$(curl -s ifconfig.me)/"
echo "   http://localhost/"
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