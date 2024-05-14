import sdl2_nim/sdl, sdl2_nim/sdl_image as img
import model

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

# Initialization sequence
proc init(app: App): bool =
  # Init SDL
  if sdl.init(sdl.InitVideo or sdl.InitTimer) != 0:
    sdl.logCritical(sdl.LogCategoryError, "Can't initialize SDL: %s",
        sdl.getError())
    return false

  if img.init(img.InitPNG) == 0:
    sdl.logCritical(sdl.LogCategoryError, "Can't initialize SDL_image: %s",
        img.getError())
    return false

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
  if app.renderer.setRenderDrawColor(0xFF, 0xFF, 0xFF, 0xFF) != 0:
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
  sdl.quit()
  img.quit()
  sdl.logInfo(sdl.LogCategoryApplication, "SDL shutdown completed")

when isMainModule:
  var
    app = App(window: nil, renderer: nil)
    exitRequested = false
    pressedKeys: seq[sdl.Keycode] = @[]

  if init(app):
    var
      deltaTime = 0.0
      ticks: uint64
      freq = sdl.getPerformanceFrequency()
      tile = Tile.new(123, 1.0, [0, 1, 2, 3, 4, 5, 6, 7])
      cell1 = Cell.new(1, 1, @[tile])
      cell2 = Cell.new(2, 2, @[tile])

    sdl.logInfo(sdl.LogCategoryApplication, "Cell1 %d",
        cell1.cellid)
    sdl.logInfo(sdl.LogCategoryApplication, "Cell2 %d",
        cell2.cellid)
    sdl.logInfo(sdl.LogCategoryApplication, "Starting main loop with %dHz", freq)

    ticks = sdl.getPerformanceCounter()

    while not exitRequested:
      # Clear screen with draw color
      if app.renderer.renderClear() != 0:
        sdl.logCritical(sdl.LogCategoryError, "Can't clear screen: %s",
            sdl.getError())

      # Update renderer
      app.renderer.renderPresent()

      # Process events
      exitRequested = events(pressedKeys)

      # Calculate delta time
      deltaTime = (sdl.getPerformanceCounter() - ticks).float / freq.float

      # Update ticks
      ticks = sdl.getPerformanceCounter()

  # Shutdown
  exit(app)
