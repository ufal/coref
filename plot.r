plot_types_distr <- function(path) {

    data <- read.delim(path, header=FALSE)

    labels <- levels(data[,3])
    table <- data[data[,3]==labels[1],]
    sum <- sum(table[,1])
    #table[,1] <- table[,1]/sum
    plot(table[order(table[,2]),2],table[order(table[,2]),1],type="l", col=1)

    for (i in 2:length(labels)) {
        table <- data[data[,3]==labels[i],]
        sum <- sum(table[,1])
        table[,1] <- table[,1]/sum
        lines(table[order(table[,2]),2],table[order(table[,2]),1], col=i)
    }

    legend("topright", labels, col=1:length(labels))
}
