// MOOSE includes
#include "ResponseSpectraCalculator.h"
#include "PostprocessorInterface.h"
#include "VectorPostprocessorInterface.h"
#include "MastodonUtils.h"
#include "ResponseHistoryBuilder.h"

registerMooseObject("diucaApp", ResponseSpectraCalculator);

InputParameters
ResponseSpectraCalculator::validParams()
{
  InputParameters params = GeneralVectorPostprocessor::validParams();
  params.addRequiredParam<VectorPostprocessorName>(
      "vectorpostprocessor",
      "Name of the ResponseHistoryBuilder vectorpostprocessor, for which "
      "response spectra are calculated.");
  params.addParam<Real>("damping_ratio", 0.05, "Damping ratio for response spectra calculation.");
  params.addParam<Real>(
      "start_frequency", 0.01, "Start frequency for the response spectra calculation.");
  params.addParam<Real>(
      "end_frequency", 100.0, "End frequency for the response spectra calculation.");
  params.addParam<unsigned int>(
      "num_frequencies", 401, "Number of frequencies for the response spectra calculation.");
  params.addRequiredRangeCheckedParam<Real>("regularize_dt",
                                            "regularize_dt>0.0",
                                            "dt for response spectra calculation. The "
                                            "acceleration response will be regularized to this dt "
                                            "prior to the response spectrum calculation.");
  // Make sure that csv files are created only at the final timestep
  params.set<bool>("contains_complete_history") = true;
  params.suppressParameter<bool>("contains_complete_history");

  params.set<ExecFlagEnum>("execute_on") = {EXEC_FINAL};
  params.suppressParameter<ExecFlagEnum>("execute_on");

  params.addClassDescription("Calculate the response spectrum at the requested nodes or points.");
  return params;
}

ResponseSpectraCalculator::ResponseSpectraCalculator(const InputParameters & parameters)
  : GeneralVectorPostprocessor(parameters),
    _xi(getParam<Real>("damping_ratio")),
    _freq_start(getParam<Real>("start_frequency")),
    _freq_end(getParam<Real>("end_frequency")),
    _freq_num(getParam<unsigned int>("num_frequencies")),
    _reg_dt(getParam<Real>("regularize_dt")),
    _frequency(declareVector("frequency")),
    _period(declareVector("period")),
    // Time vector from the response history builder vector postprocessor
    _history_time(getVectorPostprocessorValue("vectorpostprocessor", "time"))

{
  // Check for starting and ending frequency
  if (_freq_start >= _freq_end)
    mooseError("Error in " + name() +
               ". Starting frequency must be less than the ending frequency.");
  // Check that frequencies are positive
  if (_freq_start <= 0.0)
    mooseError("Error in " + name() + ". Start and end frequencies must be positive.");
  // Check for damping
  if (_xi <= 0)
    mooseError("Error in " + name() + ". Damping ratio must be positive.");
}

void
ResponseSpectraCalculator::initialSetup()
{
  const ResponseHistoryBuilder & history_vpp = getUserObjectByName<ResponseHistoryBuilder>(
      getParam<VectorPostprocessorName>("vectorpostprocessor"));
  std::vector<std::string> history_names =
      history_vpp.getHistoryNames(); // names of the vectors in responsehistorybuilder
  _history_acc.resize(history_names.size());

  // Declaring three spectrum vectors: displacement, velocity and acceleration
  // for each vector in history VPP.
  // for (const std::string & name : _varnames)
  for (std::size_t i = 0; i < history_names.size(); i++)
  {
    _history_acc[i] = history_vpp.getHistories()[i];
    _spectrum.push_back(&declareVector(history_names[i] + "_sd"));
    _spectrum.push_back(&declareVector(history_names[i] + "_sv"));
    _spectrum.push_back(&declareVector(history_names[i] + "_sa"));
  }
}

void
ResponseSpectraCalculator::initialize()
{
  _frequency.clear();
  _period.clear();
  for (VectorPostprocessorValue * ptr : _spectrum)
    ptr->clear();
}

void
ResponseSpectraCalculator::execute()
{
  for (std::size_t i = 0; i < _history_acc.size(); ++i)
  {
    // The acceleration responses may or may not have a constant time step.
    // Therefore, they are regularized by default to a constant time step by the
    // regularize function before performing the response spectrum calculations.
    std::vector<std::vector<Real>> reg_vector =
        MastodonUtils::regularize(*_history_acc[i], _history_time, _reg_dt);
    // Calculation of the response spectrum. All three spectra: displacmeent,
    // velocity and acceleration, are calculated and output into a csv file.
    std::vector<std::vector<Real>> var_spectrum = MastodonUtils::responseSpectrum(
        _freq_start, _freq_end, _freq_num, reg_vector[1], _xi, _reg_dt);
    _frequency = var_spectrum[0];
    _period = var_spectrum[1];
    *_spectrum[3 * i] = var_spectrum[2];
    *_spectrum[3 * i + 1] = var_spectrum[3];
    *_spectrum[3 * i + 2] = var_spectrum[4];
  }
}
