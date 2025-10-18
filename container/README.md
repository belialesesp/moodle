# Containers relacionados à Universidade Nós Periféricos

## Imagem base

Utilizamos a imagem base do Bitnami e personalizamos inicialmente para modificar o limite de upload do PHP, já que estas configurações não são acessíveis via Helm Chart.

Motivações adicionais para o fork:
- Mudança recente da política de suporte a artefatos abertos/público (imagens e charts) por parte da Broadcom/Bitnami. 

## Referências:
- [Fonte da imagem base (Bitnami)](https://github.com/bitnami/containers/tree/main/bitnami/moodle)
- [Comunicado de mudança de políticas por parte da Bitnami](https://github.com/bitnami/containers/issues/83267)

## TODO:
- Avaliar o uso de novas imagens que possam substituir a atual e garantindo compatibilidade com o chart
- Fork do Chart
