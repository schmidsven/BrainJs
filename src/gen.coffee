# attach the .equals method to Array's prototype to call it on any array
Array::equals = (array) ->
  # if the other array is a falsy value, return
  if !array
    return false
  # compare lengths - can save a lot of time 
  if @length != array.length
    return false
  i = 0
  l = @length
  while i < l
    # Check if we have nested arrays
    if @[i] instanceof Array and array[i] instanceof Array
      # recurse into the nested arrays
      if !@[i].equals(array[i])
        return false
    else if @[i] != array[i]
      # Warning - two different object instances will never be equal: {x:20} != {x:20}
      return false
    i++
  true

Array::diff = (array) ->
    # if the other array is a falsy value, return
    if !array
        return "!array"
    # compare lengths - can save a lot of time 
    if @length != array.length
        return "@length != array.length"
    i = 0
    l = @length
    returnArray = []
    while i < l
        # Check if we have nested arrays
        returnArray[i] =  @[i] - array[i]
        if @[i] instanceof Array and array[i] instanceof Array
            returnArray[i] = @[i].diff array[i]
        i++
    return returnArray

between = (a, b) ->
  if a > b
    this >= b and this <= a
  else
    this >= a and this <= b

Number::between = between
String::between = between
Date::between = between
##################################### END IF OVERRIDES #######################################

generateUUID = ->
    #console.log "generateUUID ***"
    d = (new Date).getTime()
    uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
      r = (d + Math.random() * 16) % 16 | 0
      d = Math.floor(d / 16)
      (if c == 'x' then r else r & 0x3 | 0x8).toString 16
    )
    return uuid

class Brain
    constructor: ->
        @trust = 200
        @id = generateUUID()
        @pulse = 10
        @conciousness = setInterval @live, @pulse
        # Initializing Memories of the Brain
        @memState = [] # Awareness (Saving the state over a reduced time)
        @memOry = []   # Longterm Memory containing Memes (What was done, how was the state)
        @memPlan = []  # Future plan containing Memes (What to do, what state to expect)
        # - - - - - - - - - - - - - - INCEPTION - - - - - - - - - - - - - - - - - - - - - -
        # This meme means EATING! Since we don't have a environment yet that could transfer
        # energy to us
        tempMeme = new Meme @, "nowEnergy+=1; console.log('Ich esse!');", @getState()
        @memOry.push tempMeme
        ##---------------------------------------------------------------------------------

        # This meme means MEDITATION!
        tempMeme = new Meme @, "//i=0;while(i<1000000){i++;};", @getState()
        # Plan for life
        @memPlan.push tempMeme


    getState: ->
        time=(new Date).getTime()
        state = []
        state.push time
        state.push nowEnergy
        state.push nowEnergy
        state.push nowEnergy

        returnState = []
        returnState.push time
        returnState.push nowEnergy
        returnState.push nowEnergy
        returnState.push nowEnergy
        return returnState

    calcAvg: (memState)->
        diffState = memState[memState.length-1].diff(memState[0])
        return diffState

    calcAvgAll: (memState)->
        # The saved States and their values
        #console.info memState.length
        sumValues=[]
        avgValues=[]
        weight=[]
        sumWeight=0
        for state in [1...memState.length]
            # difference between time of states
            weight = memState[state][0]-memState[state-1][0]
            # difference between values of states
            diffState = memState[state].diff(memState[state-1])
            sumWeight+=weight
            i=0
            for value in diffState
                if not sumValues[i]?
                    sumValues[i]=0
                sumValues[i]+=value*weight
                i+=1
        for value in sumValues
            diffStateAmount = memState.length-1
            avgValues.push value / sumWeight
        return avgValues


    urgency: (limit, threshold, now) ->
        urgncy = Math.abs(now/limit*threshold)
        return urgncy

    die: (age)->
        console.error "#{Me.id} DIED in the age of #{age}seconds !!!!!!!!!!!!!!!!!!!!!!!!!!"

    live: =>
        console.log "----------------------------------------------------------------------"
        # calculate my age...just for fun
        age = (@memOry[@memOry.length-1].time-@memOry[0].time)/1000
        # How much the state may differ from prediction
        tolerance=0.002*@memState.length
        #------------------ Run the meme
        meme = @memPlan.shift()
        meme.run()
        currentState = @getState()
        @memState.push currentState


        #------------------ Check the result
        # update how much we trust this concept
        diff = 0
     
        for value in [0...currentState.length]
            if currentState[value].between meme.expectedState[value]*(1-tolerance), meme.expectedState[value]*(1+tolerance)
                #console.info "expected value! #{meme.expectedState[value]}=#{currentState[value]}"
                meme.trust += meme.trust/10
            else
                console.error "unexpected value! #{meme.expectedState[value]}=#{currentState[value]}"
                diff = currentState[value]-meme.expectedState[value]
                meme.trust -= meme.trust/10 + diff?
        if meme.trust < min 
            meme.trust = min
        if meme.trust > max 
            meme.trust = max

        console.log "trust: #{meme.trust}"
     
        #------------------ save as a new meme in memory (experience)
        updatedMeme = new Meme meme, meme.task, currentState
        updatedMeme.duration = meme.duration
        @memOry.push updatedMeme

        #------------------ What to do next ???
        # find out how much idle time we will have
        if @memOry.length > 1
            diffMeme  = (new Date).getTime() - meme.time
            idleTime  = Math.abs(diffMeme)-meme.duration
            console.log "idleTime: #{idleTime} #{meme.duration}"

        # if we have more than 2 states we can start
        # comparing, predicting, planing, and optimizing
        if @memState.length > 2
            tendenceState = @calcAvgAll(@memState)
            console.log "tendenceState: #{tendenceState}"
            console.log "currentState: #{currentState}"
            rate=tendenceState[0]
            for i in [1...tendenceState.length]
                #########################################
                if currentState[i] <= min
                    newPulse = @die(age)
                    clearInterval @conciousness
                if currentState[i] >= max
                    newPulse = @die(age)
                    clearInterval @conciousness
                #########################################
                updatedMeme.expectedState[i] += tendenceState[i]
                ttl = Math.abs currentState[i]/tendenceState[i]*tendenceState[0]
                console.log "dead in #{ttl}"
                if tendenceState[i] < 0 
                    console.log "#{i}: sinking"

                    #foundMemes.push findInMemory i, -tendenceState[i]
                    # EFFECTIVE ---------------------------------
                    # find a point in @memState when energy was raised
                    # save the found timestamp and the raiseamount
                    # sort out when the highest raise happened

                    # If we couldn't find anything
                    # try something random
                    
                    # EFFICIENT ---------------------------------
                    # find a meme with nearly the same timestamp
                    # save the found meme into an array
                    # check the trust of this meme

                    # PREDICT -------------------------------------
                    # Find out how much time we have before we hit min
                    # Find out how many cycles that is with the current pulse


                    # For i in cycles
                    # plan memes as found in above
                    # if our selftrust is higher than the memetrust
                    # PLAN THE MEMES IN A NEW MEME! Not directly in the main @memPlan

                if tendenceState[i] > 0 
                    console.log "#{i}: raising"

            # adjust the precision of prediction depending on
            # the trust of the outcome of this memes task
            # lower trust = less data in @memState = faster prediction
            # XXX maybe also take the pulse in account here
            console.log "Drop it when it's #{@memState.length} > #{meme.trust/unit*@trust}"
            while @memState.length > meme.trust/unit*@trust
                @memState.shift()

        # # we have no memory of states... Amnesia?
        @memPlan.push updatedMeme

        for meme in @memOry
            @trust += meme.trust
        @trust = @trust/@memOry.length

        # adjust the pulse
        # if newPulse isnt @pulse
        #     @pulse = newPulse
        #     #console.log "adjust pulse: #{newPulse}"
        #     clearInterval @conciousness
        #     @conciousness = setInterval @live, @pulse
    
#
# A thought or cascade of thoughts or concept
# @trust:  I have a certain trust of the outcome ...
# @origin: I know where this thought came about ...
# @task:   Thinking is doing, a task is the smallest thing i can DO, the output!
#          What i can do is defined by my "bodymuscles"
# @duration: It's the duration the task took last time 
# @expectedState: I expect a outcome of this which is a predicted(or guessed) state
# @time: timestamp for the meme (and the state)
class Meme 
    constructor: (origin,task,expectedState) ->
        @id = generateUUID()
        @trust = origin.trust
        @origin = origin.id
        @task = task
        @duration = undefined
        @expectedState = expectedState
        @time = (new Date).getTime()
    
    run: =>
        # start Timemeasurement to find out duration of the task
        startTime = (new Date).getTime()
        # run the task
        # for i in meme.task
        eval(@task)
        endTime = (new Date).getTime()
        @duration = endTime-startTime
        #console.log @task


######################################## GENE ###################################################

Me = new Brain

# Currently i don't dynamically adjust statevalues
unit = 254
# Currently i have no percentage or some battery i can read out so i have to set
# maximum and minimum values and the value at birth
max = unit
min = 0
nowEnergy = 90

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


##---------------------------------------------------------------------------------
##           THIS IS FAKESTUFF NEEDED AS LONG AS THIS IS SOFTWARE
##---------------------------------------------------------------------------------

######################################## ENVIRONMENT ############################################
lowerEnergy= ->
    nowEnergy -= 1

# Entropie
setInterval lowerEnergy, 1000

