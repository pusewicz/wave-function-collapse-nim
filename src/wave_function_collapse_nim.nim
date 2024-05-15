import
  std/[strformat, json],
  sdl2_nim/sdl, sdl2_nim/sdl_image as img,
  sdl2_nim/sdl_ttf as ttf,
  ./model

const
  Title = "Wave Function Collapse in Nim with SDL2"
  ScreenW = 1280 # Window width
  ScreenH = 720  # Window height
  WindowFlags = 0
  RendererFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync

type
  App = ref AppObj
  AppObj = object
    window*: sdl.Window     # Window pointer
    renderer*: sdl.Renderer # Rendering state pointer

  MapJsonTile = object
    id: int
    probability: float

  MapJsonWangtile = object
    tileid: int
    wangid: array[8, int]
  MapJsonWangset = object
    name: string
    tile: int
    wangtiles: seq[MapJsonWangtile]

  MapJson = object
    image: string
    imageheight, imagewidth: int
    tileheight, tilewidth: int
    columns: int
    tiles: seq[MapJsonTile]
    wangsets: seq[MapJsonWangset]

# Render surface
proc render(renderer: sdl.Renderer,
            surface: sdl.Surface, x, y: int): bool =
  result = true
  var rect = sdl.Rect(x: x, y: y, w: surface.w, h: surface.h)
  # Convert to texture
  var texture = sdl.createTextureFromSurface(renderer, surface)
  if texture == nil:
    return false
  # Render texture
  if renderer.renderCopy(texture, nil, addr(rect)) == 0:
    result = false
  # Clean
  destroyTexture(texture)

proc loadTsj(filename: string): MapJson =
  let content = readFile(filename)
  let json = parseJson(content)
  to(json, MapJson)

proc buildTiles(tiles: seq[MapJsonTile], wangtiles: seq[MapJsonWangtile]): seq[Tile] =
  result = @[]

  for wt in wangtiles:
    # Find probability
    var probability = 1.0
    for mt in tiles:
      if mt.id == wt.tileid:
        probability = mt.probability
        break
    var wangid: array[8, int]
    for i in 0..7:
      wangid[i] = wt.wangid[i]

    result.add(Tile.new(wt.tileid, probability, wt.wangid))

# Initialization sequence
proc init(app: App): bool =
  # Init SDL
  if sdl.init(sdl.InitVideo or sdl.InitTimer) != 0:
    sdl.logCritical(sdl.LogCategoryError, "Can't initialize SDL: %s",
        sdl.getError())
    return false

  # Init SDL_image
  if img.init(img.InitPNG) == 0:
    sdl.logCritical(sdl.LogCategoryError, "Can't initialize SDL_image: %s",
        img.getError())
    return false

  # Init SDL_TTF
  if ttf.init() != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't initialize SDL_TTF: %s",
                    ttf.getError())

  # Create window
  app.window = sdl.createWindow(
    Title,
    sdl.WindowPosUndefined,
    sdl.WindowPosUndefined,
    ScreenW,
    ScreenH,
    WindowFlags)

  if app.window == nil:
    sdl.logCritical(sdl.LogCategoryError, "Can't create window: %s",
        sdl.getError())
    return false

  # Create renderer
  app.renderer = sdl.createRenderer(app.window, -1, RendererFlags)
  if app.renderer == nil:
    sdl.logCritical(sdl.LogCategoryError, "Can't create renderer: %s",
        sdl.getError())
    return false

  # Set draw color
  if app.renderer.setRenderDrawColor(0x00, 0x00, 0x00, 0xFF) != 0:
    sdl.logCritical(sdl.LogCategoryVideo, "Can't set draw color: %s",
        sdl.getError())
    return false

  sdl.logInfo(sdl.LogCategoryApplication, "SDL initialized successfully")
  return true

# Process events
proc events(pressedKeys: var seq[sdl.Keycode]): bool =
  result = false

  # Clear previous key presses
  if pressedKeys.len > 0:
    pressedKeys = @[]

  var event: sdl.Event

  while sdl.pollEvent(addr(event)) != 0:
    if event.kind == sdl.Quit:
      return true
    elif event.kind == sdl.KeyDown:
      pressedKeys.add(event.key.keysym.sym)

      if event.key.keysym.sym == sdl.K_Escape:
        return true

# Shutdown sequence
proc exit(app: App) =
  app.renderer.destroyRenderer()
  app.window.destroyWindow()
  img.quit()
  ttf.quit()
  sdl.logInfo(sdl.LogCategoryApplication, "SDL shutdown completed")
  sdl.quit()

when isMainModule:
  var
    app = App(window: nil, renderer: nil)
    exitRequested = false
    pressedKeys: seq[sdl.Keycode] = @[]
    map: Grid

  let mapJson = loadTsj("assets/map.tsj")

  var wfcModel: Model = Model.new(
    (ScreenW / mapJson.tilewidth).int,
    (ScreenH / mapJson.tileheight).int,
    buildTiles(mapJson.tiles, mapJson.wangsets[0].wangtiles)
  )

  if init(app):
    var
      font: ttf.Font
      textColor = sdl.Color(r: 0xFF, g: 0xFF, b: 0xFF)
      deltaTime = 0.0
      ticks: uint64
      freq = sdl.getPerformanceFrequency()

    font = ttf.openFont("assets/FSEX300.ttf", 16)
    if font == nil:
      sdl.logCritical(sdl.LogCategoryError, "Can't load font: %s", ttf.getError())

    discard wfcModel.solve()

    ticks = sdl.getPerformanceCounter()

    while not exitRequested:
      # Clear screen with draw color
      if app.renderer.renderClear() != 0:
        sdl.logCritical(sdl.LogCategoryError, "Can't clear screen: %s",
            sdl.getError())

      var s: sdl.Surface
      let percent = wfcModel.percent() * 100
      s = font.renderUTF8_Solid(fmt"Model percent: {percent:>3.2f}%", textColor)
      discard app.renderer.render(s, 4, 4)
      sdl.freeSurface(s)

      # Update renderer
      app.renderer.renderPresent()

      discard wfcModel.iterate()

      map = wfcModel.generateGrid()

      # Process events
      exitRequested = events(pressedKeys)

      # Calculate delta time
      deltaTime = (sdl.getPerformanceCounter() - ticks).float / freq.float

      # Update ticks
      ticks = sdl.getPerformanceCounter()

    ttf.closeFont(font)

  # Shutdown
  exit(app)
