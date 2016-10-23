defmodule Sequencer do
  alias Synthex.Context
  alias Synthex.Generator.Oscillator
  alias Synthex.Filter.Moog
  alias Synthex.Sequencer
  alias Synthex.ADSR
  alias Synthex.Output.WavWriter
  alias Synthex.File.WavHeader

  use Synthex.Math

@notes {
    "c8",
    "b7",
    "A7",
    "a7",
    "G7",
    "g7",
    "F7",
    "f7",
    "e7",
    "D7",
    "d7",
    "C7",
    "c7",
    "b6",
    "A6",
    "a6",
    "G6",
    "g6",
    "F6",
    "f6",
    "e6",
    "D6",
    "d6",
    "C6",
    "c6",
    "b5",
    "A5",
    "a5",
    "G5",
    "g5",
    "F5",
    "f5",
    "e5",
    "D5",
    "d5",
    "C5",
    "c5",
    "b4",
    "A4",
    "a4",
    "G4",
    "g4",
    "F4",
    "f4",
    "e4",
    "D4",
    "d4",
    "C4",
    "c4",
    "b3",
    "A3",
    "a3",
    "G3",
    "g3",
    "F3",
    "f3",
    "e3",
    "D3",
    "d3",
    "C3",
    "c3",
    "b2",
    "A2",
    "a2",
    "g2",
    "F2",
    "f2",
    "e2",
    "D2",
    "d2",
    "C2",
    "c2",
    "b1",
    "A1",
    "a1",
    "G1",
    "g1",
    "F1",
    "f1",
    "e1",
    "D1",
    "d1",
    "C1",
    "c1",
    "b0",
    "A0",
    "a0" 
  }

  @rate 44100

  @bpm 140
  def run(fin_data) do
    header = %WavHeader{channels: 1, rate: @rate}
    dir = System.tmp_dir() <> "/seq.wav"
    {:ok, writer} = WavWriter.open(dir, header)
    sequencer = generate_song(fin_data) |> Sequencer.from_simple_string(Sequencer.bpm_to_duration(@bpm, 4))
    total_duration = Sequencer.sequence_duration(sequencer)

    context =
      %Context{output: writer, rate: @rate}
      |> Context.put_element(:main, :osc1, %Oscillator{algorithm: :pulse})
      |> Context.put_element(:main, :osc1_1, %Oscillator{algorithm: :sawtooth})
      |> Context.put_element(:main, :osc2, %Oscillator{algorithm: :pulse})
      |> Context.put_element(:main, :osc2_1, %Oscillator{algorithm: :sawtooth})
      |> Context.put_element(:main, :lfo, %Oscillator{algorithm: :triangle, frequency: 4})
      |> Context.put_element(:main, :adsr, ADSR.adsr(@rate, 1.0, 0.4, 0.000001, 0.4, 10, 10))
      |> Context.put_element(:main, :filter, %Moog{cutoff: 0.50, resonance: 1.1})
      |> Context.put_element(:main, :sequencer, sequencer)

    Synthex.synthesize(context, total_duration, fn (ctx) ->
      {ctx, {freq, amp}} = Context.get_sample(ctx, :main, :sequencer)
      {ctx, lfo} = Context.get_sample(ctx, :main, :lfo)
      {ctx, osc1} = Context.get_sample(ctx, :main, :osc1, %{frequency: freq, center: @pi - (lfo * @pi/1.1)})
      {ctx, osc1_1} = Context.get_sample(ctx, :main, :osc1_1, %{frequency: freq + (lfo * freq * 0.05)})
      {ctx, osc2} = Context.get_sample(ctx, :main, :osc2, %{frequency: (freq + 3.5), center: @pi - (lfo * @pi/1.1)})
      {ctx, osc2_1} = Context.get_sample(ctx, :main, :osc2_1, %{frequency: (freq + 3.5) + (lfo * freq * 0.05)})
      {ctx, adsr} = Context.get_sample(ctx, :main, :adsr, %{gate: ADSR.amplification_to_gate(amp)})
      mixed_sample = ((osc1 * 0.25) + (osc1_1 * 0.25) + (osc2 * 0.25) + (osc2_1 * 0.25)) * adsr
      Context.get_sample(ctx, :main, :filter, %{sample: mixed_sample})
    end)
    WavWriter.close(writer)
    dir
  end

  def generate_song(fin_data) do
    data = 
      Map.get(fin_data, "Elements") 
      |> List.first 
      |> Map.get("DataSeries")
    close = Map.get(data, "close") |> Map.get("values")
    high = Map.get(data, "high") |> Map.get("values")
    low = Map.get(data, "low") |> Map.get("values")
    open = Map.get(data, "open") |> Map.get("values")
    list = close ++ high ++ low ++ open
    IO.inspect list
    generate_song(list, "")
  end
  def generate_song([head | tail], song) do
    next_note = @notes |> elem(rem(round(head), tuple_size(@notes))) 
    IO.inspect rem(round(head), tuple_size(@notes))
    generate_song(tail, song <> "-" <> next_note)
  end
  def generate_song([], song) do
    song
  end
end






