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
        @trust = 111
        @id = generateUUID()
        @puls = 10
        @conciousness = setInterval @live, @puls

    getState: ->
        state = []
        state.push (new Date).getTime()
        state.push nowEnergy
        memState.push state
        return state

    calcTendence: ->
        # The saved States and their values
        #console.info memState.length
        sumValues=[]
        avgValues=[]
        for state in memState
            if not oldState?
                oldState=state
            else
                i=0
                for value in state.diff(oldState)
                    if sumValues[i]?
                        sumValues[i]=0
                    sumValues[i]+=value
                    i+=1
                oldState=state
        for value in sumValues
            avgValues.push value/sumValues.length
        return avgValues

    urgency: (limit, threshold, now) ->
        urgncy = Math.abs(now/limit*threshold)
        return urgncy

    die: (age)->
        @puls = 0
        console.error "#{Me.id} DIED in the age of #{age}seconds !!!!!!!!!!!!!!!!!!!!!!!!!!"
        return @puls

    live: =>

        #------------------ Run the meme
        meme = memPlan.shift()
        meme.run()
        currentState = @getState()
        console.log meme
        console.log currentState

        #------------------ Check the result
        # update how much we trust this concept
        tolerance=0.05
        if currentState[1].between meme.expectedState[1]*(1-tolerance), meme.expectedState[1]*(1+tolerance)
            meme.trust += 1
            newPuls = @puls+10
        else
            console.error "unexpected value! #{meme.expectedState[1]}=#{currentState[1]}"
            diff=currentState[1]-meme.expectedState[1]
            meme.trust -= Math.abs(diff)
            newPuls = @puls-diff

        if newPuls>1000
            newPuls=1000
        ################################
        if nowEnergy <= minEnergy
            age = (memOry[memOry.length-1].time-memOry[0].time)/1000
            newPuls = @die(age)
            clearInterval @conciousness
        if nowEnergy >= maxEnergy
            newPuls = @die(age)
            clearInterval @conciousness
        ################################


        #------------------ save as a new meme in memory (experience)
        updatedMeme = new Meme meme, meme.task, currentState
        updatedMeme.duration = meme.duration
        memOry.push updatedMeme

        #------------------ What to do next ???
        panic = no
        # find out how much idle time we will have
        if memOry.length > 1
            oldMeme = memOry[memOry.length-1]          
            olderMeme = memOry[memOry.length-2]
            diffMeme = olderMeme.time - oldMeme.time
            idleTime = Math.abs(diffMeme)-meme.duration
            console.log "idleTime: #{idleTime}"

        # if we have more than 2 states we can start
        # comparing, predicting, planing, and optimizing
        if memState.length > 4
            #console.log "memState.length: #{memState.length}"
            tendenceState = @calcTendence()
            if tendenceState[1] < 0 
                updatedMeme.expectedState[1] += tendenceState[1]
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
                updatedMeme.expectedState[1] += tendenceState[1]
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
            @puls = newPuls
            console.log "adjust pulse: #{newPuls}"
            clearInterval @conciousness
            @conciousness = setInterval @live, @puls
    
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
        console.log @task


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
tempMeme = new Meme Me, "nowEnergy+=1; console.log('Ich esse!');", Me.getState()
memOry.push tempMeme
##---------------------------------------------------------------------------------

# This memm means MEDITATION!
tempMeme = new Meme Me, "console.log('Ich idle!');", Me.getState()
# Plan for life
memPlan.push tempMeme



######################################## ENVIRONMENT ############################################
lowerEnergy= ->
    nowEnergy -= 3

# Entropie
setInterval lowerEnergy, 1000

