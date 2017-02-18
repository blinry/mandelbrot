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

class Images
    @images = []
    @load: (filenames) ->
        @assetsToLoad = filenames.length
        for f in filenames
            i = new Image()
            i.onload = =>
                @assetsToLoad--
                if @assetsToLoad == 0
                    @onload()

            i.src = "./images/"+f
            @images[f] = i
    @get: (filename) ->
        return @images[filename]

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
    sub: (complex) ->
        new Complex(@r-complex.r, @i-complex.i)
    div: (scalar) ->
        new Complex(@r/scalar, @i/scalar)
    mul: (scalar) ->
        new Complex(@r*scalar, @i*scalar)
    length2: ->
        @r*@r + @i*@i

class Marker
    constructor: (@pos, @name, @color) ->
        @draggable = false

        # image offset drawn on pos
        @ox = Images.get(@name).width/2
        @oy = Images.get(@name).height/2
        # image offset defining dragging center
        @dx = Images.get(@name).width/2
        @dy = Images.get(@name).height/2
        # nop

class Mandelbrot
    constructor: (@exp=2) ->
        # nop
    step: (z, c) ->
        #z2 = z.dup()
        #z2.i = Math.abs(z2.i)
        #z2.r = Math.abs(z2.r)
        #z2.pow(@exp).add(c)
        z.pow(@exp).add(c)
    iterate: (c, steps=3) ->
        z = new Complex(0,0)

        if @exp == 2
            # are we in the cardioid or the period-2 bulb?
            q = (c.r-0.25)*(c.r-0.25) + c.i*c.i
            if q*(q+(c.r-0.25)) < 0.25*c.i*c.i
                return -1

        for i in [0..steps]
            z = @step(z, c)

            if z.r*z.r+z.i*z.i > 4
                return i
        return -1

class Steps
    step: (z, c) ->
        @squareNext = not @squareNext
        if @squareNext
            z.add(c)
        else
            z.pow(2)
    iterate: (c, steps=0) ->
        z = new Complex(0,0)
        @squareNext = false

        for i in [0..steps*2]
            z = @step(z, c)
        return -1

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
    hue2rgb: (p, q, t) ->
        t += 1 if t < 0
        t -= 1 if t > 1
        return p + (q - p) * 6 * t if t < 1/6
        return q if t < 1/2
        return p + (q - p) * (2/3 - t) * 6 if t < 2/3
        return p

    gray: -> new Color @h, 0, @l, @a

class Palette
    constructor: (@name="rainbow") ->
        # nop
    color: (i) ->
        if i == -1
            return new Color(0, 0, 0, 1)
        switch @name
            when "gray"
                return new Color(0, 0, (i*2).mod(360), 1)
            when "rainbow"
                return new Color((i).mod(360), 80, 60, 1)
            when "bw"
                return new Color(0, 100, 100, 1)
            when "zebra"
                return new Color(i.mod(2)*180+90, 100, 40, 1)
            when "colordemo"
                return new Color((i*50).mod(360), 80, 60, 1)

class Canvas
    constructor: ->
        @width = 500
        @height = 500

        @drawFractal = true
        @drawAxes = true
        @drawIteration = true
        @restrictToReal = false

        @depth = 100
        @maxDepth = 100
        @fractal = new Mandelbrot()
        @palette = new Palette("gray")
        @traceSize = 5

        @zoomControls = false
        @stepControls = false

        @zoomHook = ->
            # nop
        @updateHook = ->
            # nop
    init: (id) ->
        div = document.getElementById(id)
        #instructions = document.createElement("p")
        #instructions.innerHTML = "Do stuff!"
        topControls = document.createElement("div")
        topControls.setAttribute("class", "controls")
        bottomControls = topControls.cloneNode()
        layers = document.createElement("div")
        layers.setAttribute("class", "layers")
        @bgCanvas = document.createElement("canvas")
        @bgCanvas.width = @width
        @bgCanvas.height = @height
        @fgCanvas = @bgCanvas.cloneNode()

        resetButton = document.createElement("button")
        resetButton.innerHTML = "Reset"
        resetButton.onclick = =>
            @zoomReset()

        zoomInButton = document.createElement("button")
        zoomInButton.innerHTML = "+"
        zoomInButton.onclick = =>
            @zoomIn(@flag.pos)

        zoomOutButton = document.createElement("button")
        zoomOutButton.innerHTML = "-"
        zoomOutButton.onclick = =>
            @zoomOut(@flag.pos)

        stepCounter = document.createElement("span")
        stepCounter.innerHTML = "Step "+@depth

        timeSlider = document.createElement("input")
        timeSlider.setAttribute("type", "range")
        timeSlider.setAttribute("min", "0")
        timeSlider.setAttribute("max", @maxDepth)
        if @halfSteps
            timeSlider.setAttribute("step", 0.5)
        timeSlider.setAttribute("value", @depth)
        timeSlider.setAttribute("style", "width: "+@width+"px")
        timeSlider.oninput = =>
            # the first half-step does nothing
            if timeSlider.value == "0.5"
                timeSlider.value = "0"
            @depth = timeSlider.value
            stepCounter.innerHTML = "Step "+@depth
            @draw()
            @updateHook()

        paletteCanvas = document.createElement("canvas")
        paletteCanvas.setAttribute("width", @width)
        paletteCanvas.setAttribute("height", 20)
        paletteCanvas.setAttribute("style", "width: "+@width+" height: "+20+" ")

        #div.appendChild(instructions)
        div.appendChild(topControls)
        div.appendChild(layers)
        div.appendChild(bottomControls)
        if @zoomControls
            topControls.appendChild(resetButton)
            topControls.appendChild(zoomInButton)
            topControls.appendChild(zoomOutButton)
        if @stepControls
            bottomControls.appendChild(timeSlider)
            bottomControls.appendChild(stepCounter)
            bottomControls.appendChild(paletteCanvas)
        layers.appendChild(@bgCanvas)
        layers.appendChild(@fgCanvas)

        @bg = @bgCanvas.getContext("2d")
        @fg = @fgCanvas.getContext("2d")
        @slider = paletteCanvas.getContext("2d")

        @data = @bg.getImageData(0, 0, @width, @height)

        @mouse = new Complex(0,0)

        # markers
        @flag = new Marker(new Complex(0.3,-0.3), "flag.png", new Color(90, 80, 50, 1))
        if @restrictToReal
            @flag.pos.i = 0
        @flag.draggable = true
        @flag.ox = 2
        @flag.oy = Images.get("flag.png").height-2
        @flag.dx = Images.get("flag.png").width/2
        @flag.dy = Images.get("flag.png").height/4
        @bunny = new Marker(new Complex(0,0), "bunny.png", new Color(180, 80, 50, 1))
        @markers = [@bunny, @flag]

        @dragging = undefined

        @mousedown = false
        @fgCanvas.onmousedown = (event) =>
            if event.which == 1 # left
                @mousedown = true
                rect = @fgCanvas.getBoundingClientRect()
                @mouse = @toWorld(event.clientX-rect.left, event.clientY-rect.top)

                if @drawIteration
                    for marker in @markers
                        if marker.draggable
                            if @mouseOverMarker(marker)
                                @dragging = marker
                                @fgCanvas.style.cursor = "move"

                @draw()
            else if event.which == 2 # middle
                rect = @fgCanvas.getBoundingClientRect()
                @mouse = @toWorld(event.clientX-rect.left, event.clientY-rect.top)
                @draw()
            return false

        @fgCanvas.onmouseup = (event) =>
            if event.which == 1 # left
                @mousedown = false
                if @dragging
                    @dragging = undefined
                else if @zoomControls
                    @zoomIn(@mouse)
                @fgCanvas.style.cursor = "auto"

        @fgCanvas.onmousemove = (event) =>
            rect = @fgCanvas.getBoundingClientRect()
            @mouse = @toWorld(event.clientX-rect.left, event.clientY-rect.top)
            if @drawIteration
                if @dragging
                    offset = new Complex((-@dragging.dx+@dragging.ox)/@zoom, -(-@dragging.dy+@dragging.oy)/@zoom)
                    @dragging.pos = @mouse.add(offset)
                    if @restrictToReal
                        @dragging.pos.i = 0

                    @updateHook()
                else
                    for marker in @markers
                        if marker.draggable
                            if @mouseOverMarker(marker)
                                @fgCanvas.style.cursor = "pointer"
                            else
                                @fgCanvas.style.cursor = "auto"
            if @drawTrace and @dragging
                for dx in [-@traceSize..@traceSize]
                    for dy in [-@traceSize..@traceSize]
                        [x, y] = @fromWorld(@flag.pos)
                        xx = x+dx
                        yy = y+dy
                        xx = Math.floor(xx)
                        yy = Math.floor(yy)
                        offset = (@width*yy+xx)*4
                        cc = @toWorld(xx, yy)
                        i = @fractal.iterate(cc, 20)
                        col = @palette.color(i)
                        [r,g,b,a] = col.rgba()
                        @data.data[offset++] = r
                        @data.data[offset++] = g
                        @data.data[offset++] = b
                        @data.data[offset++] = a
                @bg.putImageData(@data, 0, 0)
            @draw()

        touchHandler = (event) =>
            touches = event.changedTouches
            first = touches[0]
            type = ""
            switch event.type
                when "touchstart"
                    type = "mousedown"
                when "touchmove"
                    type = "mousemove"
                when "touchend"
                    type = "mouseup"
                else
                    return

            # initMouseEvent(type, canBubble, cancelable, view, clickCount, 
            #                screenX, screenY, clientX, clientY, ctrlKey, 
            #                altKey, shiftKey, metaKey, button, relatedTarget);

            simulatedEvent = document.createEvent("MouseEvent")
            simulatedEvent.initMouseEvent(type, true, true, window, 1,
                                          first.screenX, first.screenY,
                                          first.clientX, first.clientY, false,
                                          false, false, false, 0, null)

            first.target.dispatchEvent(simulatedEvent)
            event.preventDefault()

        @fgCanvas.ontouchstart = touchHandler
        @fgCanvas.ontouchmove = touchHandler
        @fgCanvas.ontouchend = touchHandler
        @fgCanvas.ontouchcancel = touchHandler

        @zoomReset()
        @drawSlider()

    toWorld: (x, y) ->
        r = (x-@width/2)/@zoom+@center.r
        i = -(y-@height/2)/@zoom+@center.i
        new Complex(r, i)
    fromWorld: (c) ->
        x = (c.r-@center.r)*@zoom+@width/2
        y = -(c.i-@center.i)*@zoom+@height/2
        return [x, y]
    mouseOverMarker: (marker) ->
        [x, y] = @fromWorld(marker.pos)
        [mx, my] = @fromWorld(@mouse)
        x = x+marker.dx-marker.ox
        y = y+marker.dy-marker.oy
        return Math.pow(x-mx, 2) + Math.pow(y-my, 2) < Math.pow(25, 2)
    zoomIn: (c) ->
        @zoom *= 2
        @zoomCount++
        @center = @center.add(c).div(2)
        @draw(true)
        @zoomHook(@zoomCount)
        @updateHook()
    zoomOut: (c) ->
        @zoom /= 2
        @zoomCount--
        @center = @center.mul(2).sub(c)
        @draw(true)
        @zoomHook(@zoomCount)
        @updateHook()
    zoomReset: ->
        @zoom = @width/4.2
        @center = new Complex(0, 0)
        @draw(true)
        @zoomCount = 0
        @zoomHook(@zoomCount)
        @updateHook()
    clearBg: ->
        @bg.clearRect 0, 0, @width, @height
        @data = @bg.getImageData(0, 0, @width, @height)
    clearFg: ->
        @fg.clearRect 0, 0, @width, @height
    #drawReal: ->
    #    @clearFg()

    #    [ox, oy] = @fromWorld(new Complex(0,0))
    #    [x1, y1] = @fromWorld(new Complex(-2,0))
    #    [x2, y2] = @fromWorld(new Complex(2,0))
    #    [mx, my] = @fromWorld(@mouse)

    #    @fg.lineWidth = 1
    #    @fg.strokeStyle = "black"

    #    @fg.beginPath()
    #    @fg.moveTo(x1, oy)
    #    @fg.lineTo(x2, oy)
    #    @fg.stroke()

    #    @fg.lineWidth = 5
    #    @fg.strokeStyle = "red"

    #    @fg.beginPath()
    #    @fg.moveTo(ox, oy)
    #    @fg.lineTo(mx, oy)
    #    @fg.stroke()

    #    @fg.textAlign = "center"
    #    @fg.font = "20px sans-serif"
    #    @fg.fillStyle = "red"
    #    @fg.fillText(@mouse.r.toFixed(2), (mx+ox)/2, oy-5)
    #drawComplex: ->
    #    @fg.clearRect 0, 0, @width, @height

    #    [ox, oy] = @fromWorld(new Complex(0,0))
    #    [mx, my] = @fromWorld(@mouse)

    #    @fg.lineWidth = 5

    #    @fg.strokeStyle = "black"
    #    @fg.beginPath()
    #    @fg.moveTo(ox, oy)
    #    @fg.lineTo(mx, my)
    #    @fg.stroke()

    #    @fg.lineWidth = 2
    #    @fg.strokeStyle = "red"
    #    @fg.setLineDash([5, 5])

    #    @fg.beginPath()
    #    @fg.moveTo(ox, my)
    #    @fg.lineTo(mx, my)
    #    @fg.stroke()

    #    @fg.strokeStyle = "blue"

    #    @fg.beginPath()
    #    @fg.moveTo(mx, oy)
    #    @fg.lineTo(mx, my)
    #    @fg.stroke()

    #    @fg.setLineDash([])

    #    @fg.textAlign = "center"
    #    @fg.font = "20px sans-serif"
    #    text = @mouse.r
    #    @fg.fillStyle = "red"
    #    @fg.fillText(@mouse.r.toFixed(2), (mx+ox)/2, my-5)

    #    @fg.fillStyle = "blue"
    #    @fg.textAlign = "left"
    #    @fg.fillText(@mouse.i.toFixed(2)+" i", mx+5, (my+ox)/2+5)

    #    #@fg.fillText(text, mx+5, my-5)
    #    #@fg.fillStyle = "black"
    #    #offset = @fg.measureText(text).width
    #    #if @mouse.i >= 0
    #    #    text = "+"
    #    #else
    #    #    text = "-"
    #    #@fg.fillText(text, mx+5+offset, my-5)
    #    #@fg.fillStyle = "blue"
    #    #offset2 = @fg.measureText(text).width
    #    #text = @mouse.i+"i"
    #    #@fg.fillText(text, mx+5+offset+offset2, my-5)
    #drawSquare: ->
    #    @fg.clearRect 0, 0, @width, @height

    #    [ox, oy] = @fromWorld(new Complex(0,0))
    #    [mx, my] = @fromWorld(@mouse)
    #    [mx2, my2] = @fromWorld(@mouse.pow(2))

    #    @fg.beginPath()
    #    @fg.arc(ox, oy, 1*@zoom, 0, 2*Math.PI, false)
    #    @fg.stroke()
    #    @fg.beginPath()
    #    @fg.arc(ox, oy, 2*@zoom, 0, 2*Math.PI, false)
    #    @fg.stroke()

    #    @fg.lineWidth = 5
    #    @fg.strokeStyle = "black"

    #    @fg.beginPath()
    #    @fg.moveTo(ox, ox)
    #    @fg.lineTo(mx, my)
    #    @fg.stroke()

    #    @fg.beginPath()
    #    @fg.moveTo(ox, ox)
    #    @fg.lineTo(mx2, my2)
    #    @fg.stroke()

    #    @fg.textAlign = "left"
    #    @fg.font = "20px sans-serif"
    #    @fg.fillStyle = "black"
    #    @fg.fillText("c", mx+5, my-5)

    #    @fg.textAlign = "left"
    #    @fg.font = "20px sans-serif"
    #    @fg.fillStyle = "black"
    #    @fg.fillText("c^2", mx2+5, my2-5)
    #drawStep: ->
    #    @fg.clearRect 0, 0, @width, @height

    #    [ox, oy] = @fromWorld(new Complex(0,0))

    #    [mx, my] = @fromWorld(@mouse)
    #    [mx2, my2] = @fromWorld(@mouse.pow(2))
    #    [mx3, my3] = @fromWorld(@mouse.pow(2).add(@mouse))

    #    @fg.lineWidth = 5
    #    @fg.strokeStyle = "black"

    #    @fg.beginPath()
    #    @fg.moveTo(ox, ox)
    #    @fg.lineTo(mx, my)
    #    @fg.stroke()

    #    @fg.beginPath()
    #    @fg.moveTo(ox, ox)
    #    @fg.lineTo(mx2, my2)
    #    @fg.stroke()

    #    @fg.beginPath()
    #    @fg.moveTo(mx2, my2)
    #    @fg.lineTo(mx3, my3)
    #    @fg.stroke()

    #    @fg.textAlign = "left"
    #    @fg.font = "20px sans-serif"
    #    @fg.fillStyle = "black"
    #    @fg.fillText("c", mx+5, my-5)

    #    @fg.textAlign = "left"
    #    @fg.font = "20px sans-serif"
    #    @fg.fillStyle = "black"
    #    @fg.fillText("c^2", mx2+5, my2-5)

    #    @fg.textAlign = "left"
    #    @fg.font = "20px sans-serif"
    #    @fg.fillStyle = "black"
    #    @fg.fillText("c^2+c", mx3+5, my3-5)

    #drawBorder: ->
    #    @fg.lineWidth = 20
    #    @fg.strokeStyle = @palette.color(@fractal.iterate(@mouse, 20)).string()
    #    [x1, y1] = @fromWorld(new Complex(-2,-2))
    #    [x2, y2] = @fromWorld(new Complex(2,2))

    #    @fg.beginPath()
    #    @fg.moveTo(x1, y1)
    #    @fg.lineTo(x2, y1)
    #    @fg.lineTo(x2, y2)
    #    @fg.lineTo(x1, y2)
    #    @fg.lineTo(x1, y1)
    #    #@fg.arc(ox, oy, @zoom*2+@fg.lineWidth/2, 0, 2*Math.PI, false)
    #    @fg.stroke()

    drawSlider: ->
        w = @slider.canvas.clientWidth
        h = @slider.canvas.clientHeight
        for x in [0..w-1]
            for y in [0..h-1]
                @slider.fillStyle = @palette.color(x/w*@maxDepth).string()
                #console.log(@slider.fillStyle)
                @slider.fillRect(x, 0, 1, h)
                #@slider.fill()

    draw: (drawBg=false) ->
        if drawBg and @drawFractal
            @clearBg()
            offset = 0
            for y in [0..@height-1]
                for x in [0..@width-1]
                    c = @toWorld(x, y)
                    [r,g,b,a] = @palette.color(@fractal.iterate(c, 20*Math.log2(@zoom))).rgba()
                    @data.data[offset++] = r
                    @data.data[offset++] = g
                    @data.data[offset++] = b
                    @data.data[offset++] = a
            @bg.putImageData(@data, 0, 0)
        @clearFg()
        if @drawAxes
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

            @fg.setLineDash([5, 5])

            @fg.beginPath()
            @fg.arc(ox, oy, @zoom, 0, 2*Math.PI, false)
            @fg.stroke()

            @fg.beginPath()
            @fg.arc(ox, oy, @zoom*2, 0, 2*Math.PI, false)
            @fg.stroke()

            @fg.setLineDash([])

            @fg.textAlign = "center"
            @fg.font = "20px sans-serif"
            @fg.fillStyle = "black"

            [x, y] = @fromWorld(new Complex(1,0))
            @fg.fillText("1", x, y)
            [x, y] = @fromWorld(new Complex(-1,0))
            @fg.fillText("-1", x, y)
            [x, y] = @fromWorld(new Complex(0,1))
            @fg.fillText("1", x, y)
            [x, y] = @fromWorld(new Complex(0,-1))
            @fg.fillText("-1", x, y)
            [x, y] = @fromWorld(new Complex(2,0))
            @fg.fillText("2", x, y)
            [x, y] = @fromWorld(new Complex(-2,0))
            @fg.fillText("-2", x, y)
            [x, y] = @fromWorld(new Complex(0,2))
            @fg.fillText("2", x, y)
            [x, y] = @fromWorld(new Complex(0,-2))
            @fg.fillText("-2", x, y)
        if @drawIteration
            @fg.strokeStyle = "blue"
            @fg.lineWidth = 0.5
            @fg.fillStyle = "blue"

            c = @flag.pos
            @bunny.pos = new Complex(0, 0)
            @fractal.squareNext = true

            if @depth > 0
                stepCount = @depth
                if @halfSteps
                    stepCount = @depth*2
                for i in [1..stepCount]
                    [x1, y1] = @fromWorld(@bunny.pos)
                    z2 = @fractal.step(@bunny.pos, c)
                    [x2, y2] = @fromWorld(z2)

                    #@fg.strokeStyle = @fractal.palette.color(i).string()
                    @fg.beginPath()
                    @fg.moveTo(x1, y1)
                    @fg.lineTo(x2, y2)
                    @fg.stroke()

                    if (not @halfSteps) or i.mod(2) == 0
                        @fg.beginPath()
                        @fg.arc(x2, y2, 2, 0, 2*Math.PI, false)
                        @fg.fill()

                    @bunny.pos = z2

                    if z2.r*z2.r + z2.i*z2.i > 4
                        break

            for marker in @markers
                [x, y] = @fromWorld(marker.pos)
                #@fg.fillStyle = marker.color.string()
                #@fg.beginPath()
                #@fg.arc(x, y, 5, 0, 2*Math.PI, false)
                #@fg.fill()
                i = Images.get(marker.name)
                @fg.drawImage(i, x-marker.ox, y-marker.oy)

Images.onload = ->
    demoDivs = document.getElementsByClassName("demo")
    demos = {}
    for demo in demoDivs
        id = demo.id
        canvas = new Canvas()
        demos[id] = canvas
        switch id
            when "plain"
                zc = document.getElementById("zoomcount")
                zp = document.getElementById("zoompersons")
                zr = document.getElementById("zoomremark")

                canvas.drawAxes = false
                canvas.drawIteration = false
                canvas.zoomControls = true
                canvas.zoomHook = (level) ->
                    if level == 1
                        zc.innerHTML = level+" time"
                    else
                        zc.innerHTML = level+" times"
                    humans = Math.floor(Math.pow(0.25, level)*7.5e9)
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

            #when "real"
            #    canvas.drawFractal = false
            #    canvas.depth = 0
            #    canvas.restrictToReal = true
            #    canvas.uiLevel = 0
            when "complex"
                canvas.drawFractal = false
                canvas.depth = 0
            when "walk"
                canvas.drawFractal = false
                canvas.depth = 0
                canvas.maxDepth = 1
                canvas.fractal = new Mandelbrot()
                canvas.stepControls = true
            when "hop"
                canvas.drawFractal = false
                canvas.depth = 1
                canvas.maxDepth = 1.5
                canvas.halfSteps = true
                canvas.fractal = new Steps()
                canvas.stepControls = true
            when "step"
                canvas.drawFractal = false
                canvas.depth = 0
                canvas.maxDepth = 2
                canvas.halfSteps = true
                canvas.fractal = new Steps()
                canvas.stepControls = true
            when "steps"
                canvas.drawFractal = false
                canvas.depth = 0
                canvas.maxDepth = 4
                canvas.halfSteps = true
                canvas.fractal = new Steps()
                canvas.stepControls = true
                canvas.updateHook = =>
                    if demos["fullsteps"]
                        demos["fullsteps"].flag.pos = demos["steps"].flag.pos
                        demos["fullsteps"].draw()
            when "fullsteps"
                canvas.drawFractal = false
                canvas.depth = 0
                canvas.maxDepth = 4
                canvas.stepControls = true
                canvas.updateHook = =>
                    if demos["steps"]
                        demos["steps"].flag.pos = demos["fullsteps"].flag.pos
                        demos["steps"].flag.pos = demos["fullsteps"].flag.pos
                        demos["steps"].draw()
            when "iteration"
                canvas.drawFractal = false
                canvas.depth = 0
                canvas.maxDepth = 100
                canvas.stepControls = true
            when "scribble"
                canvas.drawFractal = false
                canvas.drawTrace = true
                canvas.depth = 10
                canvas.palette = new Palette("bw")
                canvas.stepControls = true
            when "color"
                canvas.drawFractal = false
                canvas.drawTrace = true
                canvas.depth = 10
                canvas.palette = new Palette("colordemo")
                canvas.stepControls = true
            when "sandbox"
                canvas.zoomControls = true
                canvas.stepControls = true
        canvas.init(id)
    ## plain
    #zoomCount = 0

    #plain = new Canvas("plain")
    #plain.drawFractal()

    #calcCount = ->


    #calcCount()

    #plain.click = (c) =>
    #    plain.zoomIn(c)
    #    zoomCount++
    #    calcCount()
    #    plain.drawFractal()

    #document.getElementById("plain-reset").onclick = =>
    #    plain.zoom = plain.width/4
    #    plain.center = new Complex(0, 0)
    #    zoomCount = 0
    #    calcCount()
    #    plain.drawFractal()

    ## exp
    #exp = new Canvas("exp")
    #exp.draw()

    #exp.click = (c) =>
    #    exp.zoomIn(c)
    #    exp.draw()

    #document.getElementById("exp-reset").onclick = =>
    #    exp.zoom = exp.width/4
    #    exp.center = new Complex(0, 0)
    #    exp.draw()
    #exp.move = (c) =>
    #    exp.drawIteration()

    #expExp = document.getElementById("exp-exp")
    #expExp.oninput = =>
    #    exp.fractal.exp = expExp.value
    #    exp.draw()

    ## real
    #real = new Canvas("real")
    #real.drawReal()
    #real.move = (c) =>
    #    real.drawReal()

    ## complex
    #complex = new Canvas("complex")
    #complex.drawComplex()
    #complex.move = (c) =>
    #    complex.drawComplex()

    ## square
    #square = new Canvas("square")
    #square.drawSquare()
    #square.move = (c) =>
    #    square.drawSquare()

    ## step
    #step = new Canvas("step")
    #step.drawStep()
    #step.move = (c) =>
    #    step.drawStep()

    ## iteration
    #iteration = new Canvas("iteration")
    #iteration.drawIteration()
    #iteration.move = (c) =>
    #    iteration.drawIteration()

    ## scribble
    #scribble = new Canvas("scribble")
    #scribble.fractal.palette = new Palette("bw")
    #scribble.drawIteration()
    #scribble.drawBorder()
    #scribble.move = (c) =>
    #    scribble.addPoint(c, 5)
    #    scribble.drawIteration()
    #    scribble.drawBorder()
    #document.getElementById("scribble-reset").onclick = =>
    #    scribble.clearBg()

    ## color
    #color = new Canvas("color")
    #color.fractal.palette = new Palette("colordemo")
    #color.drawIteration()
    #color.drawBorder()
    #color.move = (c) =>
    #    color.addPoint(c, 10)
    #    color.drawIteration()
    #    color.drawBorder()
    #document.getElementById("color-reset").onclick = =>
    #    color.clearBg()

    ## zoomiter
    #zoomiter = new Canvas("zoomiter")
    #zoomiter.drawFractal()
    #zoomiter.drawIteration()
    #zoomiter.click = (c) =>
    #    zoomiter.zoomIn(c)
    #    zoomiter.drawFractal()
    #    zoomiter.drawIteration()
    #zoomiter.middleClick = (c) =>
    #    zoomiter.zoomOut(c)
    #    zoomiter.drawFractal()
    #    zoomiter.drawIteration()
    #zoomiter.move = (c) =>
    #    zoomiter.drawIteration()
    #document.getElementById("zoomiter-reset").onclick = =>
    #    zoomiter.zoom = zoomiter.width/4
    #    zoomiter.center = new Complex(0, 0)
    #    zoomiter.draw()

    ## sandbox
    #sandbox = new Canvas("sandbox")
    #sandbox.draw()

    ##sandbox.click = (c) =>
    ##    sandbox.zoomIn(c)
    ##    sandbox.draw()

    #document.getElementById("sandbox-reset").onclick = =>
    #    sandbox.zoom = sandbox.width/4
    #    sandbox.center = new Complex(0, 0)
    #    sandbox.draw()
    #document.getElementById("sandbox-slider").oninput = ->
    #    sandbox.depth = this.value
    #    sandbox.drawIteration()
    #    sandbox.drawMarkers()
    #sandbox.move = (c) =>
    #    sandbox.drawIteration()
    #    sandbox.drawMarkers()

Images.load([
    "bunny.png"
    "flag.png"
])
