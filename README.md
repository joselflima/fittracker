# FitTracker

Diário pessoal de musculação, corrida, hidratação, sono e exames. Rails 8.1.4.1, Hotwire (Turbo e Stimulus) e SQLite. A interface é em português e o resumo diário usa o fuso de São Paulo.

## Uso local

Com Docker Compose e Make instalados, execute `make up` e `make user`. O segundo comando pede e-mail e senha no terminal. Abra [o app local](http://localhost:3100). Para escolher outra porta, use `FITTRACKER_PORT=3101 make up`.

| Comando | Função |
| --- | --- |
| `make test` | Prepara o SQLite de teste e executa a suíte em um contêiner temporário |
| `make lint` | Executa RuboCop |
| `make check` | Executa testes e lint |
| `make logs` | Acompanha os logs |
| `make ps` | Mostra o estado do serviço |
| `make down` | Encerra os contêineres e mantém o volume |
| `make help` | Lista os comandos |

Na aba **Hoje**, cada lançamento de água soma ao total e salvar o sono substitui a duração do dia. Em **Treinos**, o cronômetro continua a partir do horário salvo mesmo após fechar a página. Na corrida, você pode usar o tempo do cronômetro ou informar o do relógio. A aba **Evolução** usa a maior carga de cada dia em treinos finalizados. **Exames** organiza resultados por indicador e unidade de medida.

## Desenvolvimento com TDD

Escreva primeiro um teste que descreva a mudança e rode-o para confirmar a falha esperada. Implemente a mudança, rode o teste novamente e finalize com `make check`. O banco de teste é separado do desenvolvimento. Em produção, Rails usa arquivos SQLite para os bancos principal, de cache, filas e Action Cable no volume `fittracker_storage`.

## Produção

O [FitTracker na VPS](https://fittracker.srv1625057.hstgr.cloud) usa a rede externa `shared_net` do Traefik, o entrypoint `websecure` e o resolvedor `letsencrypt`. O DNS aponta o subdomínio à VPS. O Compose de produção não expõe portas no host.

A cada push na `main`, o GitHub Actions executa os testes e o RuboCop em Docker e constrói a imagem de produção. Após aprovação, o job de deploy envia o SHA por SSH. O comando restrito na VPS confere a revisão atual da main, constrói a imagem a partir dessa revisão e aguarda a saúde do serviço. O pipeline verifica o endpoint HTTPS público.

A VPS mantém `/docker/fittracker/compose.production.yaml`, `/docker/fittracker/.env` com `SECRET_KEY_BASE` e, após o primeiro deploy, `deployed-revision`. O comando `script/deploy` fica instalado como `/usr/local/sbin/fittracker-deploy`. Atualizações a esses dois arquivos operacionais precisam ser instaladas na VPS por um administrador. O usuário SSH dedicado `fittracker-ci` só aceita o comando fixo com um SHA. A chave privada e a identificação verificada do host ficam nos secrets `VPS_DEPLOY_KEY` e `VPS_KNOWN_HOSTS` do repositório.

Para criar uma conta de produção, na VPS execute:

```sh
cd /docker/fittracker
export APP_REVISION="$(cat deployed-revision)"
docker compose -f compose.production.yaml exec web bin/rails fittracker:user
```

No mesmo diretório e com a revisão exportada, use `docker compose -f compose.production.yaml ps` ou `docker compose -f compose.production.yaml logs -f web`. Faça backup consistente dos bancos SQLite antes de intervenções no volume de produção.
