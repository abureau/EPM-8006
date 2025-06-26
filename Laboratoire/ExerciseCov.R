ds = read.table("exercise.dat",na.string=".")
names(ds) = c("id","group","y0","y2","y4","y6","y8","y10","y12")

exlong <- reshape(ds, idvar="id",varying=c("y0","y2","y4","y6","y8","y10","y12"), v.names="y",timevar="time", time=0:6, direction="long")

exlong <- subset(exlong, time!=1 & time!=5)

attach(exlong)

day <- time*2

day.f <- factor(day, c(0,4,6,8,12))

group.f <- factor(group, c(1,2))


newtime <- time

newtime[time==0] <- 1

newtime[time==2] <- 2

newtime[time==3] <- 3

newtime[time==4] <- 4

newtime[time==6] <- 5



library(nlme)

# Unstructured Covariance (REML Estimation)

model1 <- gls(y ~ group.f*day.f, na.action=na.omit,
    corr=corSymm(, form= ~ newtime | id),
    weights = varIdent(form = ~ 1 | newtime))

summary(model1)

# Autoregressive Covariance (REML Estimation)

model2 <- gls(y ~ group.f*day.f, na.action=na.omit,
corr=corAR1(, form= ~ newtime | id))

summary(model2)

# Exponential Covariance (REML Estimation)

model3 <- gls(y ~ group.f*day.f, na.action=na.omit,
corr=corExp(, form= ~ day | id))

summary(model3)

anova(model1,model2)


anova(model1,model3)


anova(model2,model3)
