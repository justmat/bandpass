Engine_Bandpass : CroneEngine {
  var <synth;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    SynthDef(\Filter, {
      arg inL, inR, out, freq=440.0, bandWidth=1.0, inputGain=1.0;
      var in, sig;
      
      in = [In.ar(inL), In.ar(inR)];
      
      sig = {
        BBandPass.ar(in,
          freq,
          bandWidth
        ); 
      };

      Out.ar(out, sig.softclip);
    }).add;

    context.server.sync;

    synth = Synth.new(\Filter, [
      \inL, context.in_b[0].index,      
      \inR, context.in_b[1].index,
      \out, context.out_b.index],
    context.xg);

    this.addCommand("freq", "f", {|msg|
      synth.set(\freq, msg[1]);
    });
    
    this.addCommand("bandWidth", "f", {|msg|
      synth.set(\res, msg[1]);
    }); 

  }

  free {
    synth.free;
  }
}

