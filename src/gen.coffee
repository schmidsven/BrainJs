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

##################################### END IF OVERRIDES #######################################

class Brain
    constructor: ->
        @trust = 111
        @id = generateUUID()
        @puls = 10
        @awareness = setInterval @live, @puls

    checkState: ->
        nowState = new State
        nowState.values[1] = nowEnergy
        memState.push nowState
        return nowState

    calcTendence: ->
        # The saved States and their values
        console.info memState.length
        stateDiff = []
        avgValues=[]
        for state in memState
            if oldState?
                stateDiff.unshift state.values.diff(oldState.values)
                console.info state.values.diff(oldState.values)
            oldState=state

        # The diffs of the States, should bi 1 less than the States
        console.info stateDiff.length
        for values in stateDiff
            i=0
            for value in values
                if avgValues[i]?
                    avgValues[i]=0
                avgValues[i]+=value
                console.info values[i]
                console.info avgValues[i]

        for value in values
            value=value/values.length
        console.info values
        return values

    urgency: (limit, threshold, now) ->
        urgncy = Math.abs(now/limit*threshold)
        return urgncy

    die: ->
        @puls = 0
        console.error "DEAD!!!!!!!!!!!!!!!!!!!!!!!!!!"
        return @puls

    live: =>
        urgency = @urgency maxEnergy, 0.8, nowEnergy
        newPuls = @puls/(urgency*urgency)
        if newPuls>1000
            newPuls=1000

        ################################
        if nowEnergy <= minEnergy
            newPuls = @die()
            clearInterval @awareness
        if nowEnergy >= maxEnergy
            newPuls = @die()
            clearInterval @awareness
        ################################
        meme = memPlan.shift()
        console.log meme
        
        # start Timemeasurement to find out duration of the task
        startTime = (new Date).getTime()
        # run the task
        # for i in meme.task
        eval(meme.task)
        result = @checkState()
        console.log result
        endTime = (new Date).getTime()
        meme.duration = endTime-startTime

        # update how much we trust this concept
        if result.values[1] isnt meme.expectedResult.values[1]
            console.log "unexpected energylevel! #{meme.expectedResult.values[1]}=#{result.values[1]}"
            meme.trust -= Math.abs(result.values[1]-meme.expectedResult.values[1])
        else
            console.log "expected energylevel! #{meme.expectedResult.values[1]}=#{result.values[1]} Im so good!"
            meme.trust += 1

        # save the Result of this run
        updatedMeme = new Meme meme, meme.task, result
        updatedMeme.duration = meme.duration
        memOry.push updatedMeme

        ##################################
        ## What to do next ??? ###########
        ##################################

        panic = no
        # find out how much idle time we will have
        if memOry.length > 1
            oldRun = memOry[memOry.length-1]          
            olderRun = memOry[memOry.length-2]
            diffRun = olderRun.expectedResult.values[0] - oldRun.expectedResult.values[0]
            idleTime = Math.abs(diffRun)-meme.duration
            console.log "idleTime: #{idleTime}"

        # if we have more than 2 states we can start
        # comparing, predicting, planing, and optimizing
        if memState.length > 4
            #console.log "memState.length: #{memState.length}"
            tendenceState = @calcTendence()
            if tendenceState[1] < 0 
                if panic is yes and nowEnergy < 0
                    console.error "PANIC!!! #{@puls/diffRun}"
                    updatedMeme.expectedResult.values[1] += tendenceState[1]
                    memPlan.push updatedMeme
                else
                    updatedMeme.expectedResult.values[1] += tendenceState[1]
                    memPlan.push updatedMeme

                
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
                # Find out how much time we have before we hit minEnergy
                # Find out how many cycles that is with the current pulse

                # For i in cycles
                # plan memes as found in above
                # if our selftrust is higher than the memetrust
                # PLAN THE MEMES IN A NEW MEME! Not directly in the main memPlan

            if tendenceState[1] > 0 
                if panic is yes and nowEnergy > 0
                    console.error "PANIC!!! #{newPuls}"    
                    updatedMeme.expectedResult.values[1] += tendenceState[1]
                    memPlan.push updatedMeme
                else
                    updatedMeme.expectedResult.values[1] += tendenceState[1]
                    memPlan.push updatedMeme

            if tendenceState[1] is 0
                memPlan.push updatedMeme

        # # we have no memory of states... Amnesia?
        else
            memPlan.push updatedMeme

        if memState.length >= Math.round(updatedMeme.trust/15)
            memState.shift()

        # adjust the pulse
        if newPuls isnt @puls
            console.log "adjust pulse: #{newPuls}"
            clearInterval @awareness
            @awareness = setInterval @live, newPuls
    
#
# A thought or cascade of thoughts or concept
# @origin: I know where this thought came about ...
# @trust:  I have a certain trust of the outcome ...
# @result: I expect a outcome of this which is ...
#  
class Meme 
    constructor: (origin,task,expectedResult) ->
        @id = generateUUID()
        @trust = origin.trust
        @origin = origin.id
        @task = task
        @expectedResult = expectedResult
        @time = (new Date).getTime()
        @duration = undefined

#
# My current state depending on sensory input
#
class State
    constructor: ->
        #console.log "State constructor ***"
        @values = [(new Date).getTime(),0,0,0,0,0]


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
unit = unit/2
# Currently i have no percentage or some battery i can read out so i have to set
# maximum and minimum values and the value at birth
maxEnergy = unit
minEnergy = -unit
nowEnergy = 0
# - - - - - - - - - - - - - - INCEPTION - - - - - - - - - - - - - - - - - - - - - -
# This meme means EATING! Since we don't have a environment yet that could transfer
# energy to us
tempMeme = new Meme Me, "nowEnergy+=1; console.log('Ich esse!');",new State
memOry.push tempMeme
##---------------------------------------------------------------------------------

# This memm means MEDITATION!
tempMeme = new Meme Me, "console.log('Ich idle!');",new State
# Plan for life
memPlan.push tempMeme



######################################## ENVIRONMENT ############################################
lowerEnergy= ->
    nowEnergy -= 3

# Entropie
setInterval lowerEnergy, 1000

