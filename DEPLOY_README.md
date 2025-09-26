# 🚀 Guia de Deploy - Site Mia Goth

Este guia te ajuda a fazer o deploy do site Mia Goth em uma VM Ubuntu com Apache.

## 📋 Pré-requisitos

- VM Ubuntu (18.04+ recomendado)
- Acesso SSH à VM
- Usuário com privilégios sudo
- Conexão com internet na VM

## 🛠 Deploy Automático

### Passo 1: Conectar na VM
```bash
ssh usuario@ip-da-sua-vm
```

### Passo 2: Baixar o script de deploy
```bash
# Opção 1: Clonar o repositório completo
git clone https://github.com/viniruggeri/fanmade-goth.git
cd fanmade-goth

# Opção 2: Baixar apenas o script
wget https://raw.githubusercontent.com/viniruggeri/fanmade-goth/master/deploy-script.sh
```

### Passo 3: Executar o deploy
```bash
# Dar permissão de execução
chmod +x deploy-script.sh

# Executar o script
sudo ./deploy-script.sh
```

## 🔧 Deploy Manual (se preferir)

### 1. Atualizar sistema e instalar dependências
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install git apache2 curl ufw -y
```

### 2. Configurar Apache
```bash
# Iniciar e habilitar Apache
sudo systemctl start apache2
sudo systemctl enable apache2

# Verificar status
sudo systemctl status apache2
```

### 3. Baixar o site do GitHub
```bash
cd /tmp
git clone https://github.com/viniruggeri/fanmade-goth.git
cd fanmade-goth
```

### 4. Copiar arquivos para o servidor web
```bash
sudo mkdir -p /var/www/html/mia-goth
sudo cp -r * /var/www/html/mia-goth/
sudo chown -R www-data:www-data /var/www/html/mia-goth
sudo chmod -R 755 /var/www/html/mia-goth
```

### 5. Configurar VirtualHost do Apache
```bash
sudo nano /etc/apache2/sites-available/mia-goth.conf
```

Cole o seguinte conteúdo:
```apache
<VirtualHost *:80>
    ServerName _
    DocumentRoot /var/www/html/mia-goth
    
    ErrorLog ${APACHE_LOG_DIR}/mia-goth.error.log
    CustomLog ${APACHE_LOG_DIR}/mia-goth.access.log combined
    
    <LocationMatch "\.(css|js|jpg|jpeg|png|gif|ico|svg)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 month"
        Header append Cache-Control "public"
    </LocationMatch>
    
    <Location />
        SetOutputFilter DEFLATE
        SetEnvIfNoCase Request_URI \.(?:gif|jpg|jpeg|png)$ no-gzip dont-vary
        SetEnvIfNoCase Request_URI \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
    </Location>
    
    <Directory /var/www/html/mia-goth>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

### 6. Habilitar site e módulos
```bash
sudo a2enmod expires headers deflate
sudo a2ensite mia-goth.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
```

### 7. Configurar firewall (opcional)
```bash
sudo ufw enable
sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'
```

## 🌐 Acessar o Site

Após o deploy, o site estará disponível em:

- `http://localhost/` (na própria VM)
- `http://IP-DA-VM/` (de outros dispositivos na rede)

Para descobrir o IP da VM:
```bash
# IP privado (rede local)
hostname -I

# IP público (se aplicável)
curl ifconfig.me
```

## 🔄 Atualizações Futuras

Para atualizar o site quando fizer mudanças no GitHub:

```bash
cd /tmp
rm -rf fanmade-goth
git clone https://github.com/viniruggeri/fanmade-goth.git
cd fanmade-goth
sudo cp -r * /var/www/html/mia-goth/
sudo systemctl reload apache2
```

## 🐛 Solução de Problemas

### Site não carrega
```bash
# Verificar status do Apache
sudo systemctl status apache2

# Verificar logs de erro
sudo tail -f /var/log/apache2/mia-goth.error.log

# Testar configuração
sudo apache2ctl configtest
```

### Permissões incorretas
```bash
sudo chown -R www-data:www-data /var/www/html/mia-goth
sudo chmod -R 755 /var/www/html/mia-goth
```

### Firewall bloqueando
```bash
sudo ufw status
sudo ufw allow 80
sudo ufw allow 443
```

## 📁 Estrutura do Projeto

```
/var/www/html/mia-goth/
├── index.html          # Página principal
├── styles.css          # Estilos CSS
├── script.js           # JavaScript interativo
└── deploy-script.sh    # Script de deploy
```

## 📞 Contato

Em caso de problemas, verifique os logs ou entre em contato!

---
*Deploy automatizado para VM Ubuntu com Apache 🚀*