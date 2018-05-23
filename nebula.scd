(
var window, topView, channelsView, channelViews, outputView,
channelActivitySliders, centroidSlider, channelIsActive, nr_of_channels,
font, colBg, colFg, colAc,
routine, channelActivity, centroid,
oscDef, triggerChannel, triggerThreshold,
triggerPower, activityDecayFactor,
channelSynths, effectsSynth,
selectSoundSet;

triggerThreshold = 0.1;
triggerPower = 0.05;
activityDecayFactor = 0.95;

oscDef = OSCdef.new(\od, {|... args|
	args[0][(1,3..15)].do({|d, i|
		if (d > triggerThreshold) { triggerChannel.(i) }
	});
}, '/inputs/digital', nil, 57000);

triggerChannel = {|index|
	if ((index >= 0) && (index < 8)) {
		channelIsActive[index] = true;
	}
};

selectSoundSet = {
	arg index = 0, lr = 0;
	var path, filenames;

	"Loading Sound Set...".postln;

	filenames = ["0.aif", "1.aif", "2.aif", "3.aif", "4.aif", "5.aif", "6.aif", "7.aif"];
	((lr),(lr + 2)..7).do({|n|
		if ([0, 1].includes(index)) {
			path = "~/Google Drive/projects/sound-clothes/nebula/" ++ index ++ "/";
			Buffer.read(Server.default, (path ++ filenames[n]).standardizePath, bufnum:n);
		};
		channelSynths[n].free;
		channelSynths[n] = Synth.new((\channelSynth ++ index).asSymbol, [\bufnum, n]);
	});
	"Sound Set Loaded!".postln;
};

font = Font.new("Roboto Condensed", 15, false, false, true);
colBg = Color.new(31/255, 31/255, 31/255);
colFg = Color.new(1.0, 1.0, 0.85);
colAc = Color.new(242/255, 94/255, 83/255);
window = Window.new("NEBULA").front;

topView = View.new;
topView.background = colBg;
topView.fixedHeight = 30;
topView.layout = HLayout.new(
	StaticText.new.font_(font).string_("NEBULA").stringColor_(colFg)
);
topView.layout.margins = 1;
topView.layout.spacing = 1;

nr_of_channels = 8;
channelActivitySliders = nil ! nr_of_channels;
channelIsActive = false ! nr_of_channels;
channelActivity = 0.0 ! nr_of_channels;
channelSynths = nil ! nr_of_channels;

channelViews = nr_of_channels.collect({|i|
	var view, inputLabel, labelString, inputButton, buttonSurface;
	view = View.new;
	view.background = colBg;

	labelString = "C";
	if (i < 9) { labelString = labelString ++ "0"; };
	labelString = labelString ++ (i + 1);
	inputLabel = StaticText.new;
	inputLabel.string = labelString;
	inputLabel.font = font;
	inputLabel.stringColor = colFg;
	inputLabel.background = colBg;
	inputLabel.align = \center;

	buttonSurface = View.new;
	buttonSurface.background = colBg;
	buttonSurface.mouseDownAction = {|bs|
		bs.background = colAc;
		triggerChannel.(i);
	};
	buttonSurface.mouseUpAction = {|bs|
		bs.background = colBg;
	};

	inputButton = View.new;
	inputButton.background = colFg;
	inputButton.layout = HLayout.new(
		buttonSurface
	);
	inputButton.layout.margins = 1;
	inputButton.fixedWidth = 40;
	inputButton.fixedHeight = 40;

	channelActivitySliders[i] = Slider.new;
	channelActivitySliders[i].orientation = \vertical;
	channelActivitySliders[i].background = colBg;
	channelActivitySliders[i].thumbSize = 6;
	channelActivitySliders[i].knobColor = colAc;
	channelActivitySliders[i].canFocus = false;

	view.layout = VLayout.new(
		channelActivitySliders[i],
		View.new.fixedHeight_(10),
		inputLabel,
		View.new.fixedHeight_(10),
		inputButton
	);
	view.layout.margins = 0;
	view.layout.spacing = 1;
	view;
});

channelsView = View.new;
channelsView.background = colBg;
channelsView.layout = HLayout.new(*channelViews);
channelsView.layout.spacing = 1;
channelsView.layout.margins = 0;

centroidSlider = Slider.new;
centroidSlider.orientation = \horizontal;
centroidSlider.thumbSize = 6;
centroidSlider.knobColor = colAc;
centroidSlider.background = colBg;
centroidSlider.canFocus = false;

outputView = View.new;
outputView.background = colBg;
outputView.layout = VLayout.new(centroidSlider);
outputView.layout.margins = 0;

window.background = colBg;
window.layout = VLayout.new(
	topView,
	outputView,
	channelsView,
	{
		var panel, p1, l1, k1, p2, l2, k2, p3, l3, s1, s2, sItems;

		triggerPower = 0.2;
		activityDecayFactor = 0.9;

		l1 = StaticText.new();
		l1.string = "Trigger Power";
		l1.font = font;
		l1.stringColor = colFg;

		k1 = Knob.new;
		k1.value = triggerPower;
		k1.action = {|k| triggerPower = k.value };

		l2 = StaticText.new();
		l2.string = "DecayFactor";
		l2.font = font;
		l2.stringColor = colFg;

		k2 = Knob.new;
		k2.value = activityDecayFactor;
		k2.action = {|k| activityDecayFactor = k.value.linexp(0, 1, 0.7, 0.999) };

		p1 = View.new;
		p1.layout = VLayout.new(l1, k1);
		p2 = View.new;
		p2.layout = VLayout.new(l2, k2);

		l3 = StaticText.new();
		l3.string = "SoundSet";
		l3.font = font;
		l3.stringColor = colFg;

		sItems = ["Grain 1", "Grain 2", "FM", "Carpenter"];
		s1 = PopUpMenu.new;
		s1.items = sItems;
		s1.action = {|s| selectSoundSet.(s.value, 0) };

		s2 = PopUpMenu.new;
		s2.items = sItems;
		s2.action = {|s| selectSoundSet.(s.value, 1) };

		p3 = View.new;
		p3.layout = VLayout.new(l3, s1, s2);

		panel = View.new;
		panel.layout = HLayout.new(p1, p2, p3);
	}.()

);

window.layout.spacing = 1;
window.layout.margins = 10;
CmdPeriod.doOnce({ window.close });

Server.default.waitForBoot({

	SynthDef.new(\channelSynth0, {
		arg activity = 0.0, bufnum;
		var chain, reset;
		activity = LagUD.kr(activity, 0.15, 0.5);
		reset = activity > 0.01;
		chain = PlayBuf.ar(2, bufnum, 1, reset, loop:1);
		chain = chain + Warp1.ar(2, bufnum, LFDNoise3.kr(0.1).range(0, 1), 1, 0.1, -1, 12, 1, 4);
		chain = chain * activity;

		Out.ar(30, chain);
	}).send(Server.default);

	SynthDef.new(\channelSynth1, {
		arg activity = 0.0, bufnum;
		var chain, reset;
		activity = LagUD.kr(activity, 0.15, 0.5);
		reset = activity > 0.01;
		chain = (9.dbamp * PlayBuf.ar(2, bufnum, 1, reset, loop:1));
		chain = chain + Warp1.ar(2, bufnum, LFDNoise3.kr(0.111).range(0, 1), 1, 0.1, -1, 12, 1, 4);
		chain = chain + Warp1.ar(2, bufnum, LFDNoise3.kr(0.123).range(0, 1), 1, 0.1, -1, 12, 1, 4);
		chain = chain * activity;

		Out.ar(30, chain);
	}).send(Server.default);

	SynthDef.new(\channelSynth2, {
		arg activity = 0.0, bufnum;
		var chain, reset, pitch;
		activity = LagUD.kr(activity, 0.15, 0.5);

		pitch = ((bufnum * 2) + 47).midicps;
		pitch = pitch + SinOsc.ar(pitch * 3, 0, pitch * LFDNoise3.kr(0.0812).exprange(0.1, 1));
		chain = SinOsc.ar(pitch);
		chain = chain * activity;
		chain = chain * 6.neg.dbamp;
		chain = chain + FreeVerb.ar(chain, 0.5, 0.5, 0.3);
		Out.ar(30, chain);
	}).send(Server.default);

	SynthDef.new(\channelSynth3, {
		arg activity = 0.0, bufnum;
		var sig, pitch, env, detune;
		activity = LagUD.kr(activity, 0.15, 0.5);
		pitch = Select.kr(bufnum, (47 + [0, 5, 7, 10, 14, 19, 21, 24]).midicps);
		pitch = pitch + PinkNoise.kr(pitch * 0.03);
		detune = ExpRand.new(0.999, 1.001);
		sig = Saw.ar(pitch * [1, detune]) + Saw.ar(pitch * (2 + LFDNoise3.ar(0.001 * pitch).exprange(0.99, 1.01)));
		sig = DFM1.ar(sig, pitch * activity * 4);
		sig = sig * activity * 3.neg.dbamp;
		Out.ar(30, sig);
	}).add;

	SynthDef.new(\effects, {
		arg centroid = 0;
		var chain;

		centroid = Lag.kr(centroid, 0.1);

		chain = InFeedback.ar(30, 2);

		chain = HPF.ar(chain, centroid.linexp(0, 1, 10, 800));
		chain = LPF.ar(chain, centroid.linexp(0, 1, 2200, 22000));

		chain = chain + (centroid.linexp(0, 1, 0.01, 1) * GVerb.ar(chain.sum, 150, 10, 0.3, 0.5));
		chain = chain + (centroid.linexp(0, 1, 0.01, 1) * CombC.ar(chain, 0.9, [0.9, 0.8], 5));

		chain = Compander.ar(chain, chain, 12.neg.dbamp, 1, 1/4, 0.05, 0.15);
		chain = Limiter.ar(chain);
		Out.ar(0, chain);
	}).send(Server.default);

	Server.default.sync;

	selectSoundSet.(0, 0);
	selectSoundSet.(0, 1);

	Server.default.sync;

	effectsSynth = Synth.new(\effects);

	routine = fork {
		var guiCounter = 0, centroidWeights, centroidTarget, ofSend;
		centroidWeights = (1..channelActivity.size);
		centroid = 0;

		ofSend = NetAddr.new("127.0.0.1", 57100);
		loop {
			var channelActivitySum;
			nr_of_channels.do({|i|
				var delta = 0;
				if (channelIsActive[i]) { delta = triggerPower };
				channelActivity[i] = (channelActivity[i] + delta).clip(0, 1) * activityDecayFactor;
				channelIsActive[i] = false;
				channelSynths[i].set(\activity, channelActivity[i]);
			});

			channelActivitySum = channelActivity.sum;
			if (channelActivitySum > 0.001) {
				centroidTarget = (channelActivity * centroidWeights).sum / channelActivitySum;
				centroid = (0.95 * centroid) + (0.05 * centroidTarget);
			};
			effectsSynth.set(\centroid, centroid / 8);
			if (guiCounter == 8) {
				guiCounter = 0;
				defer {
					nr_of_channels.do({|i| channelActivitySliders[i].value = channelActivity[i] });
					centroidSlider.value = ((centroid - 1) / nr_of_channels) + 0.03125;
				}
			};
			guiCounter = guiCounter + 1;

			ofSend.sendMsg("/readings", *channelActivity);
			ofSend.sendMsg("/centroid", centroid / 8);
			0.020.yield;
		}
	};
});
)