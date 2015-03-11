generateUUID = ->
    #console.log "generateUUID ***"
    d = (new Date).getTime()
    uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
      r = (d + Math.random() * 16) % 16 | 0
      d = Math.floor(d / 16)
      (if c == 'x' then r else r & 0x3 | 0x8).toString 16
    )
    return uuid

#
# My current state depending on sensory input
#
class State
    constructor: ->
        #console.log "State constructor ***"
        @temperature = 0
        @energy = 0
        @position = [0,0,0]
        @time = (new Date).getTime()

#
# A thought or cascade of thoughts or concept
# @origin: I know where this thought came about ...
# @trust: I have a certain trust of the outcome ...
# expectedDiff: I expect a outcome of this which is ...
#  
class Meme 
    constructor: (@origin,@trust,task)->
        #console.log "Meme constructor ***"
        @id=generateUUID()
        @task=task
        @duration = undefined
        @expectedState = new State

#
# My Brain where state and memory are bouncing around
#
class Brain
    constructor: ->
        console.log "Brain constructor ***"
        urvertrauen = 100
        @puls = 1000
        # Space for states so we can predict into the future
        stateMemorySize = 3
        @stateMemory = []
        # Initialize Statememory
        @state = new State
        @state.temperature = 35
        @state.energy = 100
        for i in [0..stateMemorySize] by 1
            @stateMemory.push @state

        minState = new State
        minState.energy = 1
        minState.temperature = 28
        minState.time = undefined

        maxState = new State
        maxState.energy = 255
        maxState.temperature = 42
        maxState.time = undefined
        # My first meme has the task "beAwake"
        # and thats the concept of me...being awake?!
        # I can only plan memes so i have to do this
        # Because i need a plan for my life
        conceptOfMyself = new Meme(generateUUID(), urvertrauen, "this.beAwake()")
        @id = conceptOfMyself.id

        # So i can remember what i just did before
        @planMemory=[]

        # Space for memes...the Brain actually
        @conceptMemory=[]
        # Poise (Selbstvertrauen)
        @trust = conceptOfMyself.trust
        @conceptMemory.push conceptOfMyself
        # Body
        conceptOfMove = new Meme(@id, @trust, "this.move()")
        @conceptMemory.push conceptOfMove
        # Voice 
        conceptOfSay = new Meme(@id, @trust, "this.say()")
        @conceptMemory.push conceptOfSay

        # Future actions or memes
        # I plan to be me 
        @plan = []
        @plan.push (@id)



    # Pick a random task to reduce change
    randomAction:()->
        console.log "randomAction ***"
        stopthechange = Math.floor(Math.random() * @conceptMemory.length)
        meme = @conceptMemory[stopthechange]
        return meme.id

    # Cloning the currentState into StateMemory
    saveState: (state)->        
        #console.log "saveState ***"
        return state if state is null or typeof (state) isnt "object"
        temp = new State
        for key of state
          if key != "time"
            temp[key] = state[key]
        temp
        @stateMemory.push temp
        @stateMemory.shift()

    ###
    ---------------      TASKS      ------------------
    ###
    # Find a meme in Memory
    remember:(memeID) ->
        #console.log "remember ***"
        #console.log "trying to remember #{memeID}"
        for meme in @conceptMemory
            #console.log "remembering #{meme.id}"
            if meme.id == memeID
                return meme
        return false

    thinkloud: (currentTask) ->
        console.log "thinkloud ***"
        method = currentTask.split(".")[1].split("(")[0]
        console.log "I think i will #{method}"

    asExpected: (expectedState) ->
        debugger
        stateDiff = @compare @state, expectedState
        trust = 0
        if stateDiff.energy > 0
            trust-=stateDiff.energy
        if stateDiff.temperature > 0
            trust-=stateDiff.temperature
        if stateDiff.time > 0
            trust-=stateDiff.time
        return time

    # Being awake means i check my states over time and compare them 
    beAwake: =>
        console.log "beAwake ***"
        # get current state
        @saveState(@state)
        currentState = @stateMemory[@stateMemory.length-1]
        # get previous state
        previousState = @stateMemory[@stateMemory.length-2]
        # compare
        diff = @compare(previousState, currentState)
        # predict how much time we have before next energy loss
        targetTime = (new Date).getTime() + diff.time
        planposition = Math.round(-diff.time / @puls)

        #XXX implement sis läter
        # @puls=@puls-100
        # if @puls < 500
        #     @born()

        # calculate expectation
        expectedState = new State
        expectedState.energy = currentState.energy + diff.energy
        expectedState.temperature = currentState.temperature + diff.temperature
        expectedState.time = currentState.time + diff.time

        # plan to check back if every was as expected
        meme = new Meme @id, @trust, "this.asExpected(this.expectedState)" 
        meme.expectedState = expectedState
        console.log meme.id
        @plan[planposition] = meme.id
        

        # fill empty timeslots with tasks
        #   find tasksets that raise energy, order by energyconsumtion
        #   find tasksets that raise energy, order by timeconsumtion
        #   optimize predicted statechange (find causality)
        #   optimize taskset parts (find task)
        #       do the task or something random
        # save the current state

    findStateNear: (stateTime) ->
        i=0
        for laststate in @stateMemory
            if laststate.time > stateTime
                console.log "#{i}: #{stateTime} == #{laststate.time}"
                return laststate unless i == @stateMemorySize
            i+=1
        # if we couldn't find one state near, take the least oldest
        return [@stateMemory.length-2]


    # difference between saved state and current state
    compare: (memeState, currentState)=>
        # syntheticaly update my state
        @state.energy-2
        diff = new State
        diff.energy = memeState.energy - currentState.energy
        diff.temperature = memeState.temperature - currentState.temperature
        diff.time = memeState.time - currentState.time
        return diff

    # put energy to motor X
    move: (direction)->
        # syntheticaly update my state
        @state.energy-2
        console.log "move ***"
        if direction is undefined
            x = Math.floor(Math.random())
            y = Math.floor(Math.random())
            z = Math.floor(Math.random())
            direction = [x,y,z]
        return yes

    # put energy to voice (textoutput)
    say: (text)->
        # syntheticaly update my state
        @state.energy-2
        console.log "say ***"
        # we say something random, that will reduce energy
        possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        if text is undefined
            text = possible.charAt Math.floor(Math.random() * possible.length)
        console.info text
        return yes

    born: ->
        console.log "born ***"
        setInterval @beAwake,@puls

    die: ->
        console.log "die ***"
        process.exit(1);


    # Be aware of changes
    live: =>
        startTime = (new Date).getTime()
        # look what to do next
        memeID = @plan.shift()
        # remember what we ehm did
        @planMemory.push memeID

        # ----------------------------------
        # load meme
        currentMeme = @remember(memeID)
        console.log "#{currentMeme.id}: #{currentMeme.trust}"
        
        # run the meme
        if not currentMeme
            currentTask = "this.die()"
        else
            currentTask = currentMeme.task
        # run the task
        eval(currentTask)
        endTime = (new Date).getTime()

        @state.energy-2
        @state.temperature+2

        timeDiff = endTime-startTime
        oldstate = @findStateNear(startTime)

        energyDiff = oldstate.energy-@state.energy 
        tempDiff = oldstate.temperature-@state.temperature 
#        energyDiff = 2
#        tempDiff = 2

        # update meme.state
        if energyDiff == 0 and tempDiff == 0
            currentMeme.trust += 1
            currentMeme.duration = timeDiff
            @plan.push (currentMeme.id)
        else
            currentMeme.trust -= 1
            console.log "unexpected"
            @plan.push (@randomAction())        




me = new Brain
me.born()













































