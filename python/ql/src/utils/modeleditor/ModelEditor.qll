/** Provides classes and predicates related to handling APIs for the VS Code extension. */

private import python
private import semmle.python.frameworks.data.ModelsAsData
private import semmle.python.frameworks.data.internal.ApiGraphModelsExtensions
private import queries.modeling.internal.Util as Util

abstract class Endpoint instanceof Scope {
  string namespace;
  string type;
  string name;

  Endpoint() {
    this.isPublic() and
    this.getLocation().getFile() instanceof Util::RelevantFile and
    exists(string scopePath, string path, int pathIndex |
      scopePath = Util::computeScopePath(this) and
      pathIndex = scopePath.indexOf(".", 0, 0)
    |
      namespace = scopePath.prefix(pathIndex) and
      path = scopePath.suffix(pathIndex + 1) and
      (
        exists(int nameIndex | nameIndex = max(path.indexOf(".")) |
          type = path.prefix(nameIndex) and
          name = path.suffix(nameIndex + 1)
        )
        or
        not exists(path.indexOf(".")) and
        type = "" and
        name = path
      )
    )
  }

  string getNamespace() { result = namespace }

  string getFileName() { result = super.getLocation().getFile().getBaseName() }

  string toString() { result = super.toString() }

  Location getLocation() { result = super.getLocation() }

  string getType() { result = type }

  string getName() { result = name }

  abstract string getParameters();

  abstract boolean getSupportedStatus();

  abstract string getSupportedType();
}

/**
 * A callable function or method from source code.
 */
class FunctionEndpoint extends Endpoint instanceof Function {
  /**
   * Gets the parameter types of this endpoint.
   */
  override string getParameters() {
    // For now, return the names of positional and keyword parameters. We don't always have type information, so we can't return type names.
    // We don't yet handle splat params or dict splat params.
    //
    // In Python, there are three types of parameters:
    // 1. Positional-only parameters: These are parameters that can only be passed by position and not by keyword.
    // 2. Positional-or-keyword parameters: These are parameters that can be passed by position or by keyword.
    // 3. Keyword-only parameters: These are parameters that can only be passed by keyword.
    //
    // The syntax for defining these parameters is as follows:
    // ```python
    // def f(a, /, b, *, c):
    //     pass
    // ```
    // In this example, `a` is a positional-only parameter, `b` is a positional-or-keyword parameter, and `c` is a keyword-only parameter.
    //
    // We handle positional-only parameters by adding a "/" to the parameter name, reminiscient of the syntax above.
    // We handle keyword-only parameters by adding a ":" to the parameter name, to be consistent with the MaD syntax and the other languages.
    exists(int nrPosOnly, Function f |
      f = this and
      nrPosOnly = f.getPositionalParameterCount()
    |
      result =
        "(" +
          concat(string key, string value |
            // TODO: Once we have information about positional-only parameters:
            // Handle positional-only parameters by adding a "/"
            value = any(int i | i.toString() = key | f.getArgName(i))
            or
            exists(Name param | param = f.getAKeywordOnlyArg() |
              param.getId() = key and
              value = key + ":"
            )
          |
            value, "," order by key
          ) + ")"
    )
  }

  /** Holds if this API has a supported summary. */
  pragma[nomagic]
  predicate hasSummary() { this instanceof SummaryCallable }

  /** Holds if this API is a known source. */
  pragma[nomagic]
  predicate isSource() { this instanceof SourceCallable }

  /** Holds if this API is a known sink. */
  pragma[nomagic]
  predicate isSink() { this instanceof SinkCallable }

  /** Holds if this API is a known neutral. */
  pragma[nomagic]
  predicate isNeutral() { this instanceof NeutralCallable }

  /**
   * Holds if this API is supported by existing CodeQL libraries, that is, it is either a
   * recognized source, sink or neutral or it has a flow summary.
   */
  predicate isSupported() {
    this.hasSummary() or this.isSource() or this.isSink() or this.isNeutral()
  }

  override boolean getSupportedStatus() {
    if this.isSupported() then result = true else result = false
  }

  override string getSupportedType() {
    this.isSink() and result = "sink"
    or
    this.isSource() and result = "source"
    or
    this.hasSummary() and result = "summary"
    or
    this.isNeutral() and result = "neutral"
    or
    not this.isSupported() and result = ""
  }
}

/**
 * A callable where there exists a MaD sink model that applies to it.
 */
class SinkCallable extends Function {
  SinkCallable() {
    exists(string type, string path |
      Util::pathToFunction(this, type, path) and
      sinkModel(type, Util::extendFunctionPath(path), _, _)
    )
  }
}

/**
 * A callable where there exists a MaD source model that applies to it.
 */
class SourceCallable extends Function {
  SourceCallable() {
    exists(string type, string path |
      Util::pathToFunction(this, type, path) and
      sourceModel(type, Util::extendFunctionPath(path), _, _)
    )
  }
}

/**
 * A callable where there exists a MaD summary model that applies to it.
 */
class SummaryCallable extends Function {
  SummaryCallable() {
    exists(string type, string path |
      Util::pathToFunction(this, type, path) and
      summaryModel(type, path, _, _, _, _)
    )
  }
}

/**
 * A callable where there exists a MaD neutral model that applies to it.
 */
class NeutralCallable extends Function {
  NeutralCallable() {
    exists(string type, string path |
      Util::pathToFunction(this, type, path) and
      neutralModel(type, path, _)
    )
  }
}
