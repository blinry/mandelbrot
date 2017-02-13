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
            tmp = Math.pow(@r*@r+@i*@i, exp/2)
            arg = Math.atan2(@i, @r)
            new Complex(tmp*Math.cos(exp*arg), tmp*Math.sin(exp*arg))
    add: (complex) ->
        new Complex(@r+complex.r, @i+complex.i)
    div: (scalar) ->
        new Complex(@r/scalar, @i/scalar)

class Mandelbrot
    constructor: (@exp=2) ->

    step: (z, c) ->
        z.pow(@exp).add(c)
    color: (c) ->
        z = new Complex(0,0)

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
                return 255*i/(100)
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

        @click = =>

        @move = =>

        @fgCanvas.onmousedown = (event) =>
            if event.which == 1 # left
                rect = @fgCanvas.getBoundingClientRect()
                @mouse = @toWorld(event.clientX-rect.left, event.clientY-rect.top)
                @click(@mouse)

        @fgCanvas.onmousemove = (event) =>
            rect = @fgCanvas.getBoundingClientRect()
            @mouse = @toWorld(event.clientX-rect.left, event.clientY-rect.top)
            @move(@mouse)

        #@fgCanvas.onmousemove = (event) =>
        #    rect = @bgCanvas.getBoundingClientRect()
        #    @mouse = @toWorld(event.clientX-rect.left, event.clientY-rect.top)
        #    @drawIteration()
    toWorld: (x, y) ->
        r = (x-@width/2)/@zoom+@center.r
        i = -(y-@height/2)/@zoom+@center.i
        new Complex(r, i)
    fromWorld: (c) ->
        x = (c.r-@center.r)*@zoom+@width/2
        y = -(c.i-@center.i)*@zoom+@height/2
        return [x, y]
    zoomIn: (c) ->
        @zoom *= 2
        @center = @center.add(c).div(2)
    addPoint: (c) ->
        for dx in [-10..10]
            for dy in [-10..10]
                [x, y] = @fromWorld(c)
                xx = x+dx
                yy = y+dy
                xx = Math.floor(xx)
                yy = Math.floor(yy)
                offset = (@width*yy+xx)*4
                cc = @toWorld(xx, yy)
                col = @fractal.color(cc)
                if col != 0 or cc.r*cc.r+cc.i*cc.i > 4
                    col = 254
                @data.data[offset++] = col
                @data.data[offset++] = col
                @data.data[offset++] = col
                @data.data[offset++] = 255
        @bg.putImageData(@data, 0, 0)
    clearBg: ->
        @bg.clearRect 0, 0, @width, @height
        @data = @bg.getImageData(0, 0, @width, @height)
    drawReal: ->
        @fg.clearRect 0, 0, @width, @height

        [ox, oy] = @fromWorld(new Complex(0,0))
        [x1, y1] = @fromWorld(new Complex(-2,0))
        [x2, y2] = @fromWorld(new Complex(2,0))
        [mx, my] = @fromWorld(@mouse)

        @fg.lineWidth = 1
        @fg.strokeStyle = "black"

        @fg.beginPath()
        @fg.moveTo(x1, oy)
        @fg.lineTo(x2, oy)
        @fg.stroke()

        @fg.lineWidth = 5
        @fg.strokeStyle = "red"

        @fg.beginPath()
        @fg.moveTo(ox, oy)
        @fg.lineTo(mx, oy)
        @fg.stroke()

        @fg.textAlign = "center"
        @fg.font = "20px sans-serif"
        @fg.fillStyle = "red"
        @fg.fillText(@mouse.r.toFixed(2), (mx+ox)/2, oy-5)
    drawComplex: ->
        @fg.clearRect 0, 0, @width, @height

        [ox, oy] = @fromWorld(new Complex(0,0))
        [mx, my] = @fromWorld(@mouse)

        @drawAxes()

        @fg.lineWidth = 5

        @fg.strokeStyle = "black"
        @fg.beginPath()
        @fg.moveTo(ox, oy)
        @fg.lineTo(mx, my)
        @fg.stroke()

        @fg.lineWidth = 2
        @fg.strokeStyle = "red"
        @fg.setLineDash([5, 5])

        @fg.beginPath()
        @fg.moveTo(ox, my)
        @fg.lineTo(mx, my)
        @fg.stroke()

        @fg.strokeStyle = "blue"

        @fg.beginPath()
        @fg.moveTo(mx, oy)
        @fg.lineTo(mx, my)
        @fg.stroke()

        @fg.setLineDash([])

        @fg.textAlign = "center"
        @fg.font = "20px sans-serif"
        text = @mouse.r
        @fg.fillStyle = "red"
        @fg.fillText(@mouse.r.toFixed(2), (mx+ox)/2, my-5)

        @fg.fillStyle = "blue"
        @fg.textAlign = "left"
        @fg.fillText(@mouse.i.toFixed(2)+" i", mx+5, (my+ox)/2+5)

        #@fg.fillText(text, mx+5, my-5)
        #@fg.fillStyle = "black"
        #offset = @fg.measureText(text).width
        #if @mouse.i >= 0
        #    text = "+"
        #else
        #    text = "-"
        #@fg.fillText(text, mx+5+offset, my-5)
        #@fg.fillStyle = "blue"
        #offset2 = @fg.measureText(text).width
        #text = @mouse.i+"i"
        #@fg.fillText(text, mx+5+offset+offset2, my-5)
    drawSquare: ->
        @fg.clearRect 0, 0, @width, @height

        [ox, oy] = @fromWorld(new Complex(0,0))
        [mx, my] = @fromWorld(@mouse)
        [mx2, my2] = @fromWorld(@mouse.pow(2))

        @drawAxes()

        @fg.lineWidth = 5
        @fg.strokeStyle = "black"

        @fg.beginPath()
        @fg.moveTo(ox, ox)
        @fg.lineTo(mx, my)
        @fg.stroke()

        @fg.beginPath()
        @fg.moveTo(ox, ox)
        @fg.lineTo(mx2, my2)
        @fg.stroke()

        @fg.textAlign = "left"
        @fg.font = "20px sans-serif"
        @fg.fillStyle = "black"
        @fg.fillText("c", mx+5, my-5)

        @fg.textAlign = "left"
        @fg.font = "20px sans-serif"
        @fg.fillStyle = "black"
        @fg.fillText("c^2", mx2+5, my2-5)
    drawStep: ->
        @fg.clearRect 0, 0, @width, @height

        @drawAxes()
        [ox, oy] = @fromWorld(new Complex(0,0))

        [mx, my] = @fromWorld(@mouse)
        [mx2, my2] = @fromWorld(@mouse.pow(2))
        [mx3, my3] = @fromWorld(@mouse.pow(2).add(@mouse))

        @fg.lineWidth = 5
        @fg.strokeStyle = "black"

        @fg.beginPath()
        @fg.moveTo(ox, ox)
        @fg.lineTo(mx, my)
        @fg.stroke()

        @fg.beginPath()
        @fg.moveTo(ox, ox)
        @fg.lineTo(mx2, my2)
        @fg.stroke()

        @fg.beginPath()
        @fg.moveTo(mx2, my2)
        @fg.lineTo(mx3, my3)
        @fg.stroke()

        @fg.textAlign = "left"
        @fg.font = "20px sans-serif"
        @fg.fillStyle = "black"
        @fg.fillText("c", mx+5, my-5)

        @fg.textAlign = "left"
        @fg.font = "20px sans-serif"
        @fg.fillStyle = "black"
        @fg.fillText("c^2", mx2+5, my2-5)

        @fg.textAlign = "left"
        @fg.font = "20px sans-serif"
        @fg.fillStyle = "black"
        @fg.fillText("c^2+c", mx3+5, my3-5)

    drawAxes: ->
        [ox, oy] = @fromWorld(new Complex(0,0))
        [x1, y1] = @fromWorld(new Complex(-2,-2))
        [x2, y2] = @fromWorld(new Complex(2,2))

        @fg.lineWidth = 1
        @fg.strokeStyle = "black"

        @fg.beginPath()
        @fg.moveTo(x1, oy)
        @fg.lineTo(x2, oy)
        @fg.stroke()

        @fg.beginPath()
        @fg.moveTo(ox, y1)
        @fg.lineTo(ox, y2)
        @fg.stroke()

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

        @drawAxes()

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

# plain
zoomCount = 0

plain = new Canvas("plain")
plain.drawFractal()
zc = document.getElementById("zoomcount")
zp = document.getElementById("zoompercent")

plain.click = (c) =>
    plain.zoomIn(c)
    zoomCount++
    zc.innerHTML = zoomCount
    zp.innerHTML = Math.pow(0.25, zoomCount)*100
    plain.drawFractal()

document.getElementById("plain-reset").onclick = =>
    plain.zoom = plain.width/4
    plain.center = new Complex(0, 0)
    zoomCount = 0
    plain.drawFractal()

# exp
exp = new Canvas("exp")
exp.draw()

exp.click = (c) =>
    exp.zoomIn(c)
    exp.draw()

document.getElementById("exp-reset").onclick = =>
    exp.zoom = exp.width/4
    exp.center = new Complex(0, 0)
    exp.draw()

expExp = document.getElementById("exp-exp")
expExp.oninput = =>
    exp.fractal.exp = expExp.value
    exp.draw()

# real
real = new Canvas("real")
real.drawReal()
real.move = (c) =>
    real.drawReal()

# complex
complex = new Canvas("complex")
complex.drawComplex()
complex.move = (c) =>
    complex.drawComplex()

# square
square = new Canvas("square")
square.drawSquare()
square.move = (c) =>
    square.drawSquare()

# step
step = new Canvas("step")
step.drawStep()
step.move = (c) =>
    step.drawStep()

# iteration
iteration = new Canvas("iteration")
iteration.drawIteration()
iteration.move = (c) =>
    iteration.drawIteration()

# scribble
scribble = new Canvas("scribble")
scribble.drawIteration()
scribble.move = (c) =>
    scribble.addPoint(c)
    scribble.drawIteration()
document.getElementById("scribble-reset").onclick = =>
    scribble.clearBg()

# zoomiter
zoomiter = new Canvas("zoomiter")
zoomiter.drawFractal()
zoomiter.drawIteration()
zoomiter.click = (c) =>
    zoomiter.zoomIn(c)
    zoomiter.drawFractal()
    zoomiter.drawIteration()
zoomiter.move = (c) =>
    zoomiter.drawIteration()
document.getElementById("zoomiter-reset").onclick = =>
    zoomiter.zoom = zoomiter.width/4
    zoomiter.center = new Complex(0, 0)
    zoomiter.draw()
