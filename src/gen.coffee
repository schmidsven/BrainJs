unit = 254
unit = unit/2

maxEnergy = unit
minEnergy = -unit

nowEnergy = 0
memState = []
memResult = []
memPlan = []

lowerEnergy= ->
    nowEnergy -= 3

# Entropie
setInterval lowerEnergy, 1000


class Brain
    constructor: ->
        @trust = 111
        @id = generateUUID()
        @puls = 10
        @awareness = setInterval @live, @puls

    checkState: ->
        nowState = new State
        nowState.energy = nowEnergy
        memState.push nowState
        return nowState

    calcEnergyTendence: ->
        tendenceEnergy = 0
        for i in [0...memState.length-1]
            for values in memState[i]
                console.log "attribute: #{attribute}"
        #   console.log "#{memState[i+1].energy} - #{memState[i].energy}"
            tendenceEnergy += memState[i+1].energy-memState[i].energy
        tendenceEnergy=tendenceEnergy/memState.length
        if nowEnergy > 0
            tendenceEnergy+=1
        tendenceEnergy=Math.round(tendenceEnergy)
        #console.info tendenceEnergy
        return tendenceEnergy

    urgency: (limit, threshold, now) ->
        urgncy = Math.abs(now/limit*threshold)
        return urgncy

    die: ->
        @puls = 0
        console.log "DEAD!!!!!!!!!!!!!!!!!!!!!!!!!!"
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
        if result.energy isnt meme.expectedResult.energy
            console.log "unexpected energylevel! #{meme.expectedResult.energy}=#{result.energy}"
            meme.trust -= Math.abs(result.energy-meme.expectedResult.energy)
        else
            console.log "expected energylevel! #{meme.expectedResult.energy}=#{result.energy} Im so good!"
            meme.trust += 1

        # save the Result of this run
        updatedMeme = new Meme meme, meme.task, result
        updatedMeme.duration = meme.duration
        memResult.push updatedMeme

        ##################################
        ## What to do next ??? ###########
        ##################################

        panic = no
        # find out how much idle time we will have
        if memResult.length > 1
            oldRun = memResult[memResult.length-1]          
            olderRun = memResult[memResult.length-2]
            diffRun = olderRun.time - oldRun.time
            idleTime = Math.abs(diffRun)-meme.duration
            console.log "idleTime: #{idleTime}"

        # if we have more than 2 states we can start
        # comparing, predicting, planing, and optimizing
        if memState.length > 2
            #console.log "memState.length: #{memState.length}"
            tendenceEnergy = @calcEnergyTendence()
            if tendenceEnergy < 0 
                if panic is yes and nowEnergy < 0
                    console.error "PANIC!!! #{@puls/diffRun}"
                    updatedMeme.expectedResult.energy += tendenceEnergy
                    memPlan.push updatedMeme
                else
                    updatedMeme.expectedResult.energy += tendenceEnergy
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

            if tendenceEnergy > 0 
                if panic is yes and nowEnergy > 0
                    console.error "PANIC!!! #{newPuls}"    
                    updatedMeme.expectedResult.energy += tendenceEnergy
                    memPlan.push updatedMeme
                else
                    updatedMeme.expectedResult.energy += tendenceEnergy
                    memPlan.push updatedMeme

            if tendenceEnergy is 0
                memPlan.push updatedMeme

        # # we have no memory of states... Amnesia?
        else
            memPlan.push updatedMeme

        if memState.length >= Math.round(updatedMeme.trust/10)
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
        @temperature = 0
        @energy = 0
        @position = [0,0,0]
        @time = (new Date).getTime()
        @values = [@time, @temperature ,@energy ,@position[0],@position[1],@position[2]]


Me = new Brain

# This meme means EATING!
tempMeme = new Meme Me, "nowEnergy+=1; console.log('Ich esse!');",new State
memResult.push tempMeme
# This memm means MEDITATION!
tempMeme = new Meme Me, "console.log('Ich idle!');",new State
memResult.push tempMeme
# Plan for life
memPlan.push tempMeme

