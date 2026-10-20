# Desenvolvimento

Tela 480×270, 60 fps, Lua. O cartucho é um zip chamado `asteroids.lupi`.

O jogo vem de [pygame-sdl1-asteroids-pc](https://github.com/humbertodias/pygame-sdl1-asteroids-pc). A nave, o asteroide, o tiro e a explosão são os sprites daquele projeto, com a nave em 16 ângulos. As quatro pedras da primeira onda usam as posições e as cores do `config.txt`, encaixadas em 480×270.

## Montar

Precisa de Lua 5.5, `zip` e do submódulo `lupi-codec`. O codec chama `magick` para ler os PNG.

```sh
git submodule update --init
make lupi
lupinho asteroids.lupi
```

| Alvo | Resultado |
| --- | --- |
| `make lupi` | `asteroids.lupi` |
| `make web` | jogo web em `.build/webgame/`, via `hldtux/lupinho-sdk` |
| `make game/codec` | pasta aberta em `dist/current` |
| `make clean` | apaga `asteroids.lupi`, `dist/` e `.build/` |

`make game/codec` copia `game.lua`, os módulos em `src/` e `media/img/` e `media/sfx/` para `.build/src` e roda `lupi-codec`. Os `.ogg` são recolocados no release se o codec não os mantiver.

Os `.lua` e o `lupi_manifest.txt` entram no zip sem compressão. O lupinho falha ao inflar esses arquivos quando ficam muito comprimidos.

Cada push na `main` publica o cartucho em [asteroids.lupi](https://github.com/humbertodias/lupi-asteroids/releases/latest/download/asteroids.lupi) (`.github/workflows/release.yml`) e a versão web em [humbertodias.github.io/lupi-asteroids](https://humbertodias.github.io/lupi-asteroids/) (`.github/workflows/pages.yml`).

`make web` monta o `.lupi` e pede ao container `hldtux/lupinho-sdk` o `make web-game`, que embute o cartucho no Lupinho em WebAssembly. A pasta `.build/webgame` recebe `media/web/fullscreen.css` ligado no `game.html`.

No Ubuntu o ImageMagick 6 não tem o comando `magick`; os workflows instalam um atalho para `identify` e `convert`. O Pages do repositório precisa estar em GitHub Actions.

## Áudio

Efeitos em `sfx.fx`, músicas em `sfx.music`. Os arquivos ficam em `media/sfx/` e entram no cartucho como `sfx/*.ogg`, sem extensão na chamada.

| Chamada | Quando |
| --- | --- |
| `sfx.fx("sfx/shoot")` | Tiro |
| `sfx.fx("sfx/thrust")` | Aceleração |
| `sfx.fx("sfx/hit")` | Asteroide grande partido |
| `sfx.fx("sfx/explosion")` | Nave destruída |
| `sfx.fx("sfx/start")` | Começo da partida |
| `sfx.fx("sfx/hover")` | Troca de item no menu |
| `sfx.fx("sfx/enter")` | Confirmação no menu |
| `sfx.music("sfx/menu")` | Telas de fora da partida |
| `sfx.music("sfx/game")` | Partida |

## Arquivos

- `game.lua` — monta os objetos e chama `update`
- `src/` — nave, asteroide, tiro, partida e telas, no mesmo desenho do pygame
- `media/img/` — nave, chama, asteroides, tiro, explosão e ícone de vida
- `media/sfx/` — sons
- `lupi-codec/` — converte o estágio em cartucho
