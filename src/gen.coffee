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

class Brain
    constructor: ->
        @trust = 10
        @id = generateUUID()
        @pulse = 10
        @conciousness = setInterval @live, @pulse

    getState: ->
        time=(new Date).getTime()
        state = []
        state.push time
        state.push nowEnergy
        state.push nowEnergy
        state.push nowEnergy
        memState.push state

        returnState = []
        returnState.push time
        returnState.push nowEnergy
        returnState.push nowEnergy
        returnState.push nowEnergy
        return returnState

    calcTendence: ->
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
        @pulse = 0
        console.error "#{Me.id} DIED in the age of #{age}seconds !!!!!!!!!!!!!!!!!!!!!!!!!!"
        return @pulse

    live: =>
        # calculate my age...just for fun
        age = (memOry[memOry.length-1].time-memOry[0].time)/1000
        # How much the state may differ from prediction
        tolerance=0.03
        #------------------ Run the meme
        meme = memPlan.shift()
        meme.run()
        currentState = @getState()
        console.log meme.trust
        #console.log currentState

        #------------------ Check the result
        # update how much we trust this concept
        diff = 0
        newPulse = @pulse
        for value in [0...currentState.length]
            if currentState[value].between meme.expectedState[value]*(1-tolerance), meme.expectedState[value]*(1+tolerance)
                #console.info "expected value! #{meme.expectedState[value]}=#{currentState[value]}"
                meme.trust += memState.length
            else
                console.error "unexpected value! #{meme.expectedState[value]}=#{currentState[value]}"
                diff += currentState[value]-meme.expectedState[value]
        meme.trust -= Math.abs(diff)
        if meme.trust < min 
            meme.trust = min
        if meme.trust > max 
            meme.trust = max

        newPulse = meme.trust*4

        ####### don't get below 60 bpm ##########
        if newPulse>1000
            newPulse=1000
        #######                        ##########
        if nowEnergy <= min
            newPulse = @die(age)
            clearInterval @conciousness
        if nowEnergy >= max
            newPulse = @die(age)
            clearInterval @conciousness
        ################################


        #------------------ save as a new meme in memory (experience)
        updatedMeme = new Meme meme, meme.task, currentState
        updatedMeme.duration = meme.duration
        memOry.push updatedMeme

        #------------------ What to do next ???
        # find out how much idle time we will have
        if memOry.length > 1
            diffMeme  = (new Date).getTime() - meme.time
            idleTime  = Math.abs(diffMeme)-meme.duration
            console.log "idleTime: #{idleTime}"



        # XXX this no good
        i=1
        # if we have more than 2 states we can start
        # comparing, predicting, planing, and optimizing
        if memState.length > 2
            tendenceState = @calcTendence()
            console.log "tendenceState: #{tendenceState}"
            for i in [1...tendenceState.length]
                if tendenceState[i] < 0 
                    updatedMeme.expectedState[i] += tendenceState[i]
                    
                    # EFFECTIVE ---------------------------------
                    # find a point in memState when energy was raised
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
                    # PLAN THE MEMES IN A NEW MEME! Not directly in the main memPlan

                if tendenceState[i] > 0 
                    updatedMeme.expectedState[i] += tendenceState[i]

        # # we have no memory of states... Amnesia?
        memPlan.push updatedMeme

        # adjust the precision of prediction depending on
        # the trust of the outcome of this memes task
        # lower trust = less data in memState = faster prediction
        # XXX maybe also take the pulse in account here
        console.log "memState.length: #{memState.length}"
        if memState.length <= meme.trust/5
            memState.shift()

        # adjust the pulse
        if newPulse isnt @pulse
            @pulse = newPulse
            console.log "adjust pulse: #{newPulse}"
            clearInterval @conciousness
            @conciousness = setInterval @live, @pulse
    
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

# Initializing Memories of the Brain
memState = [] # Awareness (Saving the state over a reduced time)
memOry = []   # Longterm Memory containing Memes (What was done, how was the state)
memPlan = []  # Future plan containing Memes (What to do, what state to expect)

##---------------------------------------------------------------------------------
##           THIS IS FAKESTUFF NEEDED AS LONG AS THIS IS SOFTWARE
##---------------------------------------------------------------------------------
# Currently i don't dynamically adjust statevalues
unit = 254
# Currently i have no percentage or some battery i can read out so i have to set
# maximum and minimum values and the value at birth
max = unit
min = 0
nowEnergy = 100
# - - - - - - - - - - - - - - INCEPTION - - - - - - - - - - - - - - - - - - - - - -
# This meme means EATING! Since we don't have a environment yet that could transfer
# energy to us
tempMeme = new Meme Me, "nowEnergy+=1; console.log('Ich esse!');", Me.getState()
memOry.push tempMeme
##---------------------------------------------------------------------------------

# This memm means MEDITATION!
tempMeme = new Meme Me, "", Me.getState()
# Plan for life
memPlan.push tempMeme



######################################## ENVIRONMENT ############################################
lowerEnergy= ->
    nowEnergy -= 3

# Entropie
setInterval lowerEnergy, 1000

