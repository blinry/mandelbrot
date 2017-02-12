class Complex
    constructor: (@r, @i) ->

    dup: ->
        new Complex(@r, @i)
    pow: (exp) ->
        if exp == 2
            new Complex(@r*@r-@i*@i, 2*@r*@i)
        else if exp == 3
            new Complex(@r*@r*@r-3*@r*@i*@i, 3*@r*@r*@i-@i*@i*@i)
        else
            tmp = Math.pow(@r*@r+@i*@i, exp/2.0)
            arg = Math.atan2(@i, @r)
            new Complex(tmp*Math.cos(exp*arg), tmp*Math.sin(exp*arg))
    add: (complex) ->
        new Complex(@r+complex.r, @i+complex.i)

class Mandelbrot
    constructor: (@exp=2) ->

    step: (z, c) ->
        z.pow(@exp).add(c)
    color: (c) ->
        z = new Complex(0,0)

        if false#mode == "mandel"
            # are we in the cardioid or the period-2 bulb?
            q = (c.r-0.25)*(c.r-0.25) + c.i*c.i
            if q*(q+(c.r-0.25)) < 0.25*c.i*c.i
                return 0

        for i in [0..100]
            z = @step(z, c)
            #[zx, zy] = f(x, y, zx, zy)
            #zy = 2*zx*zy+y
            #zx = tx-ty+x
            #tx = zx*zx
            #ty = zy*zy

            if z.r*z.r+z.i*z.i > 4
                return 255.0*i/(100)
                #return "white"
        return 0

class Canvas
    constructor: (id) ->
        @width = 400
        @height = 400

        div = document.getElementById(id)
        layers = document.createElement("div")
        layers.setAttribute("class", "layers")
        div.appendChild(layers)

        @bgCanvas = document.createElement("canvas")
        @bgCanvas.setAttribute("width", @width)
        @bgCanvas.setAttribute("height", @height)
        @fgCanvas = @bgCanvas.cloneNode()
        layers.appendChild(@bgCanvas)
        layers.appendChild(@fgCanvas)

        @bg = @bgCanvas.getContext("2d")
        @fg = @fgCanvas.getContext("2d")

        @data = @bg.getImageData(0, 0, @width, @height)

        @zoom = @width/4
        @center = new Complex(0,0)
        @mouse = new Complex(0,0)

        @fractal = new Mandelbrot()

        @fgCanvas.onmousedown = (event) =>
            if event.which == 1 # left
                rect = @fgCanvas.getBoundingClientRect()
                c = @toWorld(event.clientX-rect.left, event.clientY-rect.top)
                @click(c)

        @fgCanvas.onmousemove = (event) =>
            rect = @bgCanvas.getBoundingClientRect()
            @mouse = @toWorld(event.clientX-rect.left, event.clientY-rect.top)
            @drawIteration()
    toWorld: (x, y) ->
        r = (x-@width/2)/@zoom+@center.r
        i = (y-@height/2)/@zoom+@center.i
        new Complex(r, i)
    fromWorld: (c) ->
        return [(c.r-@center.r)*@zoom+@width/2, (c.i-@center.i)*@zoom+@height/2]
    draw: ->
        @drawFractal()
        @drawIteration()
    drawFractal: ->
        offset = 0
        for y in [0..@height-1]
            for x in [0..@width-1]
                c = @toWorld(x, y)
                col = @fractal.color(c)
                @data.data[offset++] = col
                @data.data[offset++] = col
                @data.data[offset++] = col
                @data.data[offset++] = 255

        @bg.putImageData(@data, 0, 0)
    drawIteration: ->
        @fg.clearRect 0, 0, @width, @height
        @fg.strokeStyle = "blue"
        @fg.lineWidth = 0.5
        @fg.fillStyle = "blue"

        z = new Complex(0, 0)
        c = @mouse

        for i in [0..1000]
            [x1, y1] = @fromWorld(z)
            z2 = @fractal.step(z, c)
            [x2, y2] = @fromWorld(z2)

            @fg.beginPath()
            @fg.moveTo(x1, y1)
            @fg.lineTo(x2, y2)
            @fg.stroke()
            @fg.beginPath()
            @fg.arc(x2, y2, 2, 0, 2*Math.PI, false)
            @fg.fill()

            if z2.r*z2.r+z2.i*z2*i > 4
                break

            z = z2

toWorld = (x, y) ->
    return [toWorldX(x), toWorldY(y)]

toWorldX = (x) ->

toWorldY = (y) ->

fromWorld = (x, y) ->
    return [fromWorldX(x), fromWorldY(y)]

fromWorldX = (x) ->

#drawAxes = ->
#    bgctx.strokeStyle = "black"
#    bgctx.lineWidth = 1
#
#    bgctx.beginPath()
#    bgctx.moveTo(fromWorldX(-2), fromWorldY(0))
#    bgctx.lineTo(fromWorldX(2), fromWorldY(0))
#    bgctx.stroke()
#
#    bgctx.beginPath()
#    bgctx.moveTo(fromWorldX(0),fromWorldY(-2))
#    bgctx.lineTo(fromWorldX(0),fromWorldY(2))
#    bgctx.stroke()
#
#    bgctx.beginPath()
#    bgctx.arc(fromWorldX(0), fromWorldY(0), 2*scale, 0, 2*Math.PI, false)
#    bgctx.stroke()


f = (cx, cy, zx, zy) ->
    if mode == "julia"
        #return [zx*zx-zy*zy-0.4, 2*zx*zy+0.6]
        #return [zx*zx-zy*zy+0.285, 2*zx*zy+0.01]
        return [zx*zx-zy*zy+(1-1.6180339887), 2*zx*zy]
    else
        # z^2+c
        return [zx*zx-zy*zy+cx, 2*zx*zy+cy]
        # mandelbar
        return [zx*zx-zy*zy+cx, 2*zx*zy+cy]

render = ->

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

#window.requestAnimationFrame = window.requestAnimationFrame ? window.webkitRequestAnimationFrame ? window.mozRequestAnimationFrame ? window.msRequestAnimationFrame
#window.updateCanvas = true
#window.updateBg = true
#
#canvas.onmousemove = (event) =>
#    cx = toWorldX(event.clientX)
#    cy = toWorldY(event.clientY)
#
#    window.updateCanvas = true
#
#canvas.onmousedown = (event) =>
#    if event.which == 1 # left
#        centerX = cx
#        centerY = cy
#        scale *= 2
#        window.updateCanvas = true
#        window.updateBg = true
#
#window.onkeydown = (event) =>
#    if event.keyCode == 82 # r
#        scale = 200
#        centerX = 0
#        centerY = 0
#        window.updateCanvas = true
#        window.updateBg = true

#window.onresize = (event) =>
#    canvas.width = window.innerWidth
#    canvas.height = window.innerHeight
#    window.updateCanvas = true

#window.onresize()
#drawLoop()

# plain
plain = new Canvas("plain")
plain.draw()

plain.click = (c) =>
    plain.center = c
    plain.zoom *= 2
    plain.draw()

document.getElementById("plain-reset").onclick = =>
    plain.zoom = plain.width/4
    plain.center = new Complex(0, 0)
    plain.draw()

# exp

exp = new Canvas("exp")
exp.draw()

exp.click = (c) =>
    exp.center = c
    exp.zoom *= 2
    exp.draw()

document.getElementById("exp-reset").onclick = =>
    exp.zoom = exp.width/4
    exp.center = new Complex(0, 0)
    exp.draw()

expExp = document.getElementById("exp-exp")
expExp.oninput = =>
    console.log(expExp.value)
    exp.fractal.exp = expExp.value
    exp.draw()
