set = []
scale = 200.0
centerX = 0
centerY = 0
step = 1
cx = 0
cy = 0

f = (cx, cy, zx, zy) ->
    # z^2+c
    return [zx*zx-zy*zy+cx, 2*zx*zy+cy]

square = (zx, zy) ->
    return [zx*zx-zy*zy, 2*zx*zy]

toWorld = (x, y) ->
    return [toWorldX(x), toWorldY(y)]

toWorldX = (x) ->
    (x-canvas.width/2)/scale+centerX

toWorldY = (y) ->
    (y-canvas.height/2)/scale+centerY

fromWorld = (x, y) ->
    return [fromWorldX(x), fromWorldY(y)]

fromWorldX = (x) ->
    (x-centerX)*scale+canvas.width/2

fromWorldY = (y) ->
    (y-centerY)*scale+canvas.height/2

drawAxes = ->
    bgctx.strokeStyle = "black"
    bgctx.lineWidth = 1

    bgctx.beginPath()
    bgctx.moveTo(fromWorldX(-2), fromWorldY(0))
    bgctx.lineTo(fromWorldX(2), fromWorldY(0))
    bgctx.stroke()

    bgctx.beginPath()
    bgctx.moveTo(fromWorldX(0),fromWorldY(-2))
    bgctx.lineTo(fromWorldX(0),fromWorldY(2))
    bgctx.stroke()

    bgctx.beginPath()
    bgctx.arc(fromWorldX(0), fromWorldY(0), 2*scale, 0, 2*Math.PI, false)
    bgctx.stroke()

drawIteration = ->
    ctx.strokeStyle = "blue"
    ctx.lineWidth = 0.5

    zx = 0
    zy = 0

    inSet = true
    for i in [0..1000]
        [zx2, zy2] = [zx, zy]
        [zx, zy] = f(cx, cy, zx, zy)
        ctx.beginPath()
        ctx.moveTo(fromWorldX(zx2), fromWorldY(zy2))
        ctx.lineTo(fromWorldX(zx), fromWorldY(zy))
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(fromWorldX(zx), fromWorldY(zy), 2, 0, 2*Math.PI, false)
        ctx.fillStyle = "blue"
        ctx.fill()
        if Math.sqrt(zx*zx+zy*zy) > 2
            inSet = false
            break
    if inSet
        set.push([cx,cy])

color = (x,y) ->
    zx = 0
    zy = 0

    for i in [0..50]
        [zx, zy] = f(x, y, zx, zy)
        if zx*zx+zy*zy > 4
            return "hsl(0, 0%, "+i+"%)"
            #return "white"
    return "black"

render = ->
    for x in [0..canvas.width] by step
        for y in [0..canvas.height] by step
            xx = toWorldX(x)
            yy = toWorldY(y)
            c = color(xx, yy)
            bgctx.beginPath()
            bgctx.arc(fromWorldX(xx), fromWorldY(yy), 0.5*step, 0, 2*Math.PI, false)
            bgctx.fillStyle = c
            bgctx.fill()
    console.log("done")

draw = ->
    ctx.clearRect 0, 0, canvas.width, canvas.height

    drawIteration()

    #for [x,y] in set
    #    ctx.beginPath()
    #    ctx.arc(x, y, 0.02, 0, 2*Math.PI, false)
    #    ctx.fillStyle = "green"
    #    ctx.fill()


    #[tx, ty] = square(cx, cy)
    #ctx.beginPath()
    #ctx.arc(tx, ty, 0.02, 0, 2*Math.PI, false)
    #ctx.fillStyle = "red"
    #ctx.fill()

drawBg = ->
    bgctx.clearRect 0, 0, canvas.width, canvas.height

    drawAxes()
    render()

drawLoop = ->
    requestAnimationFrame drawLoop
    if window.updateBg
        drawBg()
        window.updateBg = false
    if window.updateCanvas
        draw()
        window.updateCanvas = false

Array::add = (vector) ->
    [
        @[0] + vector[0]
        @[1] + vector[1]
    ]

Array::sub = (vector) ->
    [
        @[0] - (vector[0])
        @[1] - (vector[1])
    ]

Array::mul = (scalar) ->
    [
        @[0] * scalar
        @[1] * scalar
    ]

Array::div = (scalar) ->
    [
        @[0] / scalar
        @[1] / scalar
    ]

Array::len = -> Math.sqrt @[0] * @[0] + @[1] * @[1]

Array::nor = -> @mul 1 / @len()

Array::sum = -> @reduce ((a, b) -> a + b.a), 0

Array::rot = (theta) ->
    [
        @[0] * Math.cos(theta) - (@[1] * Math.sin(theta))
        @[0] * Math.sin(theta) + @[1] * Math.cos(theta)
    ]

canvas = document.getElementById("canvas")
ctx = canvas.getContext("2d")

bgcanvas = document.getElementById("bg")
bgctx = bgcanvas.getContext("2d")

window.requestAnimationFrame = window.requestAnimationFrame ? window.webkitRequestAnimationFrame ? window.mozRequestAnimationFrame ? window.msRequestAnimationFrame
window.updateCanvas = true
window.updateBg = true

canvas.onmousemove = (event) =>
    cx = toWorldX(event.clientX)
    cy = toWorldY(event.clientY)

    window.updateCanvas = true

canvas.onmousedown = (event) =>
    if event.which == 1 # left
        centerX = cx
        centerY = cy
        scale *= 2
        window.updateCanvas = true
        window.updateBg = true

#window.onresize = (event) =>
#    canvas.width = window.innerWidth
#    canvas.height = window.innerHeight
#    window.updateCanvas = true

#window.onresize()
drawLoop()
