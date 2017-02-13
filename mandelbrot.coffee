Number.prototype.mod = (n) ->
    ((this%n)+n)%n

toFixed = (x) ->
    if (Math.abs(x) < 1.0)
        e = parseInt(x.toString().split('e-')[1])
        if (e)
            x *= Math.pow(10,e-1)
            x = '0.' + (new Array(e)).join('0') + x.toString().substring(2)
    else
        e = parseInt(x.toString().split('+')[1])
        if (e > 20)
            e -= 20
            x /= Math.pow(10,e)
            x += (new Array(e+1)).join('0')
    return x

class Complex
    constructor: (@r, @i) ->
        # nop
    string: ->
        if @i >= 0
            ""+@r+"+"+@i+"i"
        else
            ""+@r+@i
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
        @scheme = "rainbow"
    step: (z, c) ->
        z.pow(@exp).add(c)
    color: (c, steps=3) ->
        z = new Complex(0,0)

        if @exp == 2
            # are we in the cardioid or the period-2 bulb?
            q = (c.r-0.25)*(c.r-0.25) + c.i*c.i
            if q*(q+(c.r-0.25)) < 0.25*c.i*c.i
                return new Color(0, 0, 0, 1)

        for i in [0..steps]
            z = @step(z, c)
            #[zx, zy] = f(x, y, zx, zy)
            #zy = 2*zx*zy+y
            #zx = tx-ty+x
            #tx = zx*zx
            #ty = zy*zy

            if z.r*z.r+z.i*z.i > 4
                if @scheme == "gray"
                    return new Color(0, 0, i, 1)
                else if @scheme == "rainbow"
                    return new Color((i).mod(360), 80, 60, 1)
                else if @scheme == "bw"
                    return new Color(0, 80, 60, 1)
                else if @scheme == "zebra"
                    return new Color(i.mod(2)*180+90, 100, 40, 1)
                #return "white"
        return new Color(0, 0, 0, 1)

class Color
    constructor: (@h,@s,@l,@a) ->
        # nop
    @rand: -> new Color rand(0, 360), 100, rand(20, 40), 0.8
    string: -> "hsla("+@h+","+@s+"%,"+@l+"%,"+@a+")"
    rgba: ->
        h = @h/360
        s = @s/100
        l = @l/100
        if s == 0
            rr = g = b = l #achromatic
        else
            q = if l < 0.5 then l * (1 + s) else l + s - l * s
            p = 2 * l - q
            rr = @hue2rgb(p, q, h + 1/3)
            g = @hue2rgb(p, q, h)
            b = @hue2rgb(p, q, h - 1/3)
        return [Math.round(rr * 255), Math.round(g * 255), Math.round(b * 255), Math.round(@a * 255)]
        #"#"+("0"+Math.round(rr * 255).toString(16)).slice(-2)+("0"+Math.round(g * 255).toString(16)).slice(-2)+("0"+Math.round(b * 255).toString(16)).slice(-2)
    #hue2rgb: (p, q, t) ->
    #    if t < 0
    #        t += 1
    #    if t > 1
    #        t -= 1
    #    if t < 1/6
    #        return p + (q - p) * 6 * t
    #    if t < 1/2
    #        return q
    #    if t < 2/3
    #        return p + (q - p) * (2/3 - t) * 6
    #    return p
    hue2rgb: (p, q, t) ->
        t += 1 if t < 0
        t -= 1 if t > 1
        return p + (q - p) * 6 * t if t < 1/6
        return q if t < 1/2
        return p + (q - p) * (2/3 - t) * 6 if t < 2/3
        return p

    gray: -> new Color @h, 0, @l, @a

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

        @mousedown = false
        @fgCanvas.onmousedown = (event) =>
            if event.which == 1 # left
                @mousedown = true
                rect = @fgCanvas.getBoundingClientRect()
                @mouse = @toWorld(event.clientX-rect.left, event.clientY-rect.top)
                @click(@mouse)
            return false

        @fgCanvas.onmouseup = (event) =>
            if event.which == 1 # left
                @mousedown = false

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
        if @mousedown
            for dx in [-5..5]
                for dy in [-5..5]
                    [x, y] = @fromWorld(c)
                    xx = x+dx
                    yy = y+dy
                    xx = Math.floor(xx)
                    yy = Math.floor(yy)
                    offset = (@width*yy+xx)*4
                    cc = @toWorld(xx, yy)
                    col = @fractal.color(cc, 20)
                    [r,g,b,a] = col.rgba()
                    @data.data[offset++] = r
                    @data.data[offset++] = g
                    @data.data[offset++] = b
                    @data.data[offset++] = a
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
        @fg.beginPath()
        @fg.arc(ox, oy, 1*@zoom, 0, 2*Math.PI, false)
        @fg.stroke()
        @fg.beginPath()
        @fg.arc(ox, oy, 2*@zoom, 0, 2*Math.PI, false)
        @fg.stroke()

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
    drawBorder: ->
        @fg.lineWidth = 10
        @fg.strokeStyle = @fractal.color(@mouse, 20).string()
        [x1, y1] = @fromWorld(new Complex(-2,-2))
        [x2, y2] = @fromWorld(new Complex(2,2))

        @fg.beginPath()
        @fg.moveTo(x1, y1)
        @fg.lineTo(x2, y1)
        @fg.lineTo(x2, y2)
        @fg.lineTo(x1, y2)
        @fg.lineTo(x1, y1)
        @fg.stroke()

    draw: ->
        @drawFractal()
        @drawIteration()
    drawFractal: ->
        offset = 0
        for y in [0..@height-1]
            for x in [0..@width-1]
                c = @toWorld(x, y)
                [r,g,b,a] = @fractal.color(c, 20*Math.log2(@zoom)).rgba()
                @data.data[offset++] = r
                @data.data[offset++] = g
                @data.data[offset++] = b
                @data.data[offset++] = a

        @bg.putImageData(@data, 0, 0)
    drawIteration: ->
        @fg.clearRect 0, 0, @width, @height

        @drawAxes()

        @fg.strokeStyle = "blue"
        @fg.lineWidth = 0.5
        @fg.fillStyle = "blue"

        z = new Complex(0, 0)
        c = @mouse

        for i in [0..500]
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

[h,s,l,a] = new Color(200, 80, 20, 1).rgba()

# plain
zoomCount = 0

plain = new Canvas("plain")
plain.drawFractal()
zc = document.getElementById("zoomcount")
zp = document.getElementById("zoompersons")
zr = document.getElementById("zoomremark")

calcCount = ->
    if zoomCount == 1
        zc.innerHTML = zoomCount+" time"
    else
        zc.innerHTML = zoomCount+" times"
    humans = Math.floor(Math.pow(0.25, zoomCount)*7.5e9)
    if humans == 7.5e9
        zp.innerHTML = "all"
    else if humans == 0
        zp.innerHTML = "none"
    else
        zp.innerHTML = humans
    if humans == 0
        zr.innerHTML = "This means it's very, very probable that you are the first human being ever to see this region of the Mandelbrot set!"# If you wanna give it a name, here's its coordinate: "+plain.center.string()
    else
        zr.innerHTML = ""


calcCount()

plain.click = (c) =>
    plain.zoomIn(c)
    zoomCount++
    calcCount()
    plain.drawFractal()

document.getElementById("plain-reset").onclick = =>
    plain.zoom = plain.width/4
    plain.center = new Complex(0, 0)
    zoomCount = 0
    calcCount()
    plain.drawFractal()

# exp
exp = new Canvas("exp")
exp.draw()

exp.click = (c) =>
    exp.zoomIn(c)
    exp.draw()
    exp.draw()

document.getElementById("exp-reset").onclick = =>
    exp.zoom = exp.width/4
    exp.center = new Complex(0, 0)
    exp.draw()
exp.move = (c) =>
    exp.drawIteration()

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
scribble.fractal.scheme = "bw"
scribble.drawIteration()
scribble.drawBorder()
scribble.move = (c) =>
    scribble.addPoint(c)
    scribble.drawIteration()
    scribble.drawBorder()
document.getElementById("scribble-reset").onclick = =>
    scribble.clearBg()

# color
color = new Canvas("color")
color.fractal.scheme = "rainbow"
color.drawIteration()
color.drawBorder()
color.move = (c) =>
    color.addPoint(c)
    color.drawIteration()
    color.drawBorder()
document.getElementById("color-reset").onclick = =>
    color.clearBg()

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
