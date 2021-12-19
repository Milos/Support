import Foundation
import YAMLBuilder

public typealias Composite = GitHub.Action.Composite

extension GitHub.Action {
    
    public struct Composite {
        
        public struct Step {
            var name: String?
            var shell: String
            var run: String
        }
        
        var steps: [Step]
        
    }
    
}

extension Composite: GitHub.Action.Run {
    
    public init(@CompositeStepsBuilder steps: () -> [Step]) {
        self.init(steps: steps())
    }
    
    public var yamlDescription: YAML.Map {
        "using".is("composite")
        
        "steps".is {
            for step in steps {
                YAML.Node {
                    if let name = step.name {
                        "name".is(.text(name))
                    }
                    "run".is(.text(step.run))
                    "shell".is(.text(step.shell))
                }
            }
        }
    }
    
}

extension Composite.Step {

    public init(_ name: String? = nil, shell: String, run: () -> String) {
        self.init(name: name, shell: shell, run: run())
    }

}

@resultBuilder
public class CompositeStepsBuilder: ArrayBuilder<Composite.Step> {
    
    public static func buildFinalResult(_ steps: [Composite.Step]) -> [Composite.Step] {
        steps
    }
}
