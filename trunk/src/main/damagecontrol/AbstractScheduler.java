package damagecontrol;

import java.util.Map;
import java.util.HashMap;

public abstract class AbstractScheduler implements Scheduler {
    private final Map builders = new HashMap();

    protected Builder getBuilder(String builderName) throws NoSuchBuilderException {
        Builder builder = (Builder) builders.get(builderName);
        if (builder == null) {
            throw new NoSuchBuilderException(builderName);
        }
        return builder;
    }

    public void registerBuilder(String name, Builder builder) {
        builders.put(name, builder);
    }
}
