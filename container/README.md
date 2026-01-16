# Containers relacionados à Universidade Nós Periféricos

## Contexto

Utilizamos a imagem base do Bitnami [0] e personalizamos inicialmente para modificar o limite de upload do PHP, já que estas configurações não são acessíveis via Helm Chart. (`Dockerfile`)

Porém com a mudança recente da política de suporte a artefatos abertos/público (imagens e charts) por parte da Broadcom/Bitnami [1] temos a demanda de realizar construir nossa própria imagem base e templates Helm.

### Imagem de container

Atualmente além da imagem do Bitnami [0] existe também uma imagem focada no desenvolvimento do Moodle [2]. As imagens do Bitnami têm uma conhecida preocupação com hardening, porém com a nova política temos um risco de que correções de possíveis vulnerabilidades não sejam implementada. Adicionalmente as imagens contêm uma séria de artefatos ligados à marca Bitnami, por exemplo a arquitetura de diretórios definidas nas imagens (e.g. `/opt/bitnami`). Um problema relacionado à reprodutibilidade dos builds é a utilização de artefatos pré construídos e armazenados num diretório próprio da Bitnami [3].

### Helm Chart

TODO

## Considerações gerais

- Após a versão 5.1 do Moodle há a implementação de um novo modelo de diretórios para o Moodle, com a criação da pasta `public` como única exposta diretamente pelo Web Server.
- Avaliar a posibilidade de separação entre imagens do web server (Nginx) e do PHP-FPM.
  - Do ponto de vista do deployment haveriam dois modelos possíveis: (1) Manter dois container em um pod com comunicação via socket (compartilhamento do sistema de arquivos); (2) Pods distintos com comunicação via rede.
- A complexidade encontrada no build da imagem da Bitnami não precisa ser totalmente reproduzida, mas as decisões precisam ser feitas a partir do estudo de caso desta imagem.
- É possível simplificarmos nosso build assumindo decisões acerca do web server e da base de dados. (e.g. Nginx e Postgres)
- Atualmente nossa instância produtiva utiliza a base MariaDB, o que simplifica em alguns pontos devido a ser a mais utilizada pela comunidade. Porém visto a facilidade de manutenção do Postgres uma migração seria o cenário ideal (desde que não haja perdas de informações nesse processo)


## Referências:
- [0] [Fonte da imagem base (Bitnami)](https://github.com/bitnami/containers/tree/main/bitnami/moodle)
- [1] [Comunicado de mudança de políticas por parte da Bitnami](https://github.com/bitnami/containers/issues/83267)
- [2] [Imagem para desenvolvimento Moodle](https://github.com/moodlehq/moodle-docker)
- [3] [Linha do Dockerfile da Butnami onde são baixados artefatos disponibilizados em `downloads.bitnami.com/files/stacksmith` ](https://github.com/bitnami/containers/blob/48a8b2100434b23276a2419f7418f77477e2ed0f/bitnami/moodle/5.1/debian-12/Dockerfile#L28)


## TODO:
- Avaliar o uso de novas imagens que possam substituir a atual e garantindo compatibilidade com o chart
- Fork do Chart
